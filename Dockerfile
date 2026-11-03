FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml README.md ./
COPY app ./app
COPY static ./static
RUN pip install --upgrade pip && pip install .

RUN mkdir -p /app/data
VOLUME ["/app/data"]

EXPOSE 3000
CMD ["python", "-m", "app.main"]
