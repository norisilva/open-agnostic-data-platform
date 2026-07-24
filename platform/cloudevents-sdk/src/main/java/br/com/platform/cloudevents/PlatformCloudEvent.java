package br.com.platform.cloudevents;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class PlatformCloudEvent<T> {
    
    @JsonProperty("specversion")
    private String specVersion = "1.0";

    @JsonProperty("id")
    private String id;

    @JsonProperty("source")
    private String source;

    @JsonProperty("type")
    private String type;

    @JsonProperty("time")
    private String time;

    @JsonProperty("datacontenttype")
    private String dataContentType = "application/json";

    @JsonProperty("schemaurl")
    private String schemaUrl;

    @JsonProperty("buzid")
    private String buzId;

    @JsonProperty("correlationid")
    private String correlationId;

    @JsonProperty("traceparent")
    private String traceParent;

    @JsonProperty("data")
    private T data;

    public PlatformCloudEvent() {
    }

    private PlatformCloudEvent(Builder<T> builder) {
        this.specVersion = builder.specVersion;
        this.id = builder.id != null ? builder.id : UUID.randomUUID().toString();
        this.source = builder.source;
        this.type = builder.type;
        this.time = builder.time != null ? builder.time : Instant.now().toString();
        this.dataContentType = builder.dataContentType;
        this.schemaUrl = builder.schemaUrl;
        this.buzId = builder.buzId;
        this.correlationId = builder.correlationId;
        this.traceParent = builder.traceParent;
        this.data = builder.data;
    }

    public static <T> Builder<T> builder() {
        return new Builder<>();
    }

    // Getters
    public String getSpecVersion() { return specVersion; }
    public String getId() { return id; }
    public String getSource() { return source; }
    public String getType() { return type; }
    public String getTime() { return time; }
    public String getDataContentType() { return dataContentType; }
    public String getSchemaUrl() { return schemaUrl; }
    public String getBuzId() { return buzId; }
    public String getCorrelationId() { return correlationId; }
    public String getTraceParent() { return traceParent; }
    public T getData() { return data; }

    public static class Builder<T> {
        private String specVersion = "1.0";
        private String id;
        private String source;
        private String type;
        private String time;
        private String dataContentType = "application/json";
        private String schemaUrl;
        private String buzId;
        private String correlationId;
        private String traceParent;
        private T data;

        public Builder<T> specVersion(String specVersion) {
            this.specVersion = specVersion;
            return this;
        }

        public Builder<T> id(String id) {
            this.id = id;
            return this;
        }

        public Builder<T> source(String source) {
            this.source = source;
            return this;
        }

        public Builder<T> type(String type) {
            this.type = type;
            return this;
        }

        public Builder<T> time(String time) {
            this.time = time;
            return this;
        }

        public Builder<T> dataContentType(String dataContentType) {
            this.dataContentType = dataContentType;
            return this;
        }

        public Builder<T> schemaUrl(String schemaUrl) {
            this.schemaUrl = schemaUrl;
            return this;
        }

        public Builder<T> buzId(String buzId) {
            this.buzId = buzId;
            return this;
        }

        public Builder<T> correlationId(String correlationId) {
            this.correlationId = correlationId;
            return this;
        }

        public Builder<T> traceParent(String traceParent) {
            this.traceParent = traceParent;
            return this;
        }

        public Builder<T> data(T data) {
            this.data = data;
            return this;
        }

        public PlatformCloudEvent<T> build() {
            return new PlatformCloudEvent<>(this);
        }
    }
}
