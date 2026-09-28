FROM python:3.12-slim

WORKDIR /app

# Copy requirements first so Docker caches this layer — it only
# re-runs pip install when requirements.txt actually changes, not on
# every code edit.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 8000

# Run as a non-root user inside the container — a small but real
# security improvement over the default (root).
RUN useradd --create-home appuser
USER appuser

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]