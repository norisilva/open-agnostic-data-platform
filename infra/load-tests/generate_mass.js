const fs = require('fs');

const NUMBER_OF_RECORDS = 10000;
const outputFile = 'infra/load-tests/mass.csv';

// We want to generate diverse idempotency keys and cell ids
const cellIds = ['cell-payments', 'cell-renegotiation', 'cell-onboarding', 'cell-cards'];
const eventTypes = ['payment.created', 'renegotiation.requested', 'card.issued', 'invoice.paid'];

let csvContent = 'cellId,eventType,idempotencyKey,payload\n';

for (let i = 0; i < NUMBER_OF_RECORDS; i++) {
  const cellId = cellIds[Math.floor(Math.random() * cellIds.length)];
  const eventType = eventTypes[Math.floor(Math.random() * eventTypes.length)];
  const idempotencyKey = `idem-${Date.now()}-${i}-${Math.random().toString(36).substring(7)}`;
  
  // Create a JSON payload, escape inner quotes for CSV
  const payload = JSON.stringify({
    timestamp: new Date().toISOString(),
    amount: Math.round(Math.random() * 10000) / 100,
    customerId: `cust-${Math.floor(Math.random() * 5000)}`,
    description: "Load test generated payload"
  }).replace(/"/g, '""');

  csvContent += `${cellId},${eventType},${idempotencyKey},"${payload}"\n`;
}

fs.writeFileSync(outputFile, csvContent);
console.log(`Generated ${NUMBER_OF_RECORDS} records in ${outputFile}`);
