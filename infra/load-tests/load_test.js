import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import papaparse from 'https://jslib.k6.io/papaparse/5.1.1/index.js';

// Load the generated CSV mass
const massData = new SharedArray('test_mass', function () {
  const res = papaparse.parse(open('./mass.csv'), { header: true }).data;
  // Filter out any empty rows
  return res.filter(row => row.cellId && row.eventType);
});

export const options = {
  stages: [
    { duration: '10s', target: 50 },  // Ramp up to 50 users
    { duration: '30s', target: 200 }, // Ramp up to 200 users
    { duration: '1m', target: 200 },  // Sustain 200 users
    { duration: '10s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<50', 'p(99)<100'], // Fast return rule!
    http_req_failed: ['rate<0.01'],               // Error rate < 1%
  },
};

export default function () {
  // Pick a random record from the mass
  const randomRecord = massData[Math.floor(Math.random() * massData.length)];

  const url = 'http://localhost:8080/api/v1/events';
  
  const payload = JSON.stringify({
    payload: JSON.parse(randomRecord.payload)
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'X-Cell-Id': randomRecord.cellId,
      'X-Event-Type': randomRecord.eventType,
      'Idempotency-Key': randomRecord.idempotencyKey,
    },
  };

  const res = http.post(url, payload, params);

  check(res, {
    'is status 202': (r) => r.status === 202,
    'has event id': (r) => r.json('id') !== undefined,
  });

  sleep(0.1);
}
