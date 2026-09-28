from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="devops-lab-app")

# This one line wires up request counters, latency histograms, and
# in-progress request gauges, and exposes them all at GET /metrics in
# the text format Prometheus expects. You don't have to hand-write any
# metric code for the basics — this is the standard way to instrument
# a FastAPI app.
Instrumentator().instrument(app).expose(app)


@app.get("/")
def read_root():
    return {"message": "Hello from devops-lab! This is a real app, not the nginx placeholder."}


@app.get("/health")
def health_check():
    # Kept deliberately simple: if the process can respond, it's healthy.
    # A more thorough check might verify a database connection here —
    # a good addition once this app actually has a database.
    return {"status": "healthy"}