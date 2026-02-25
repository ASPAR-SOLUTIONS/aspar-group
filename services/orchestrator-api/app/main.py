from typing import Dict

from fastapi import Depends, FastAPI, HTTPException
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from starlette.responses import Response

from shared.schemas import (
    JobRequest,
    JobResult,
    RegistryServiceCreate,
    RegistryServicePatch,
    RegistryServiceResponse,
    ServiceHealth,
)
from shared.utils import configure_json_logger

from .db import get_db
from .models import RegistryService

app = FastAPI(title="NOTORIA Orchestrator API", version="0.4.0")
logger = configure_json_logger("orchestrator-api")

JOBS_TOTAL = Counter("notoria_jobs_total", "Total jobs created")
JOB_RETRIES_TOTAL = Counter("notoria_job_retries_total", "Total job retries")
REGISTRY_UPSERTS_TOTAL = Counter("notoria_registry_upserts_total", "Total registry inserts/updates")

STORE: Dict[str, JobResult] = {}


@app.post("/v1/jobs", response_model=JobResult, status_code=202)
def create_job(payload: JobRequest) -> JobResult:
    if payload.job_id in STORE:
        raise HTTPException(status_code=409, detail="job_id already exists")

    result = JobResult(
        job_id=payload.job_id,
        status="queued",
        outputs={"accepted": True, "format": payload.format},
        metrics={"script_chars": len(payload.script)},
        errors=[],
    )
    STORE[result.job_id] = result
    JOBS_TOTAL.inc()
    logger.info(f"job_created job_id={result.job_id} avatar_id={payload.avatar_id}")
    return result


@app.get("/v1/jobs/{job_id}", response_model=JobResult)
def get_job(job_id: str) -> JobResult:
    job = STORE.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="job not found")
    return job


@app.post("/v1/jobs/{job_id}/retry", response_model=JobResult)
def retry_job(job_id: str) -> JobResult:
    job = STORE.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="job not found")

    updated = JobResult(**{**job.model_dump(), "status": "queued"})
    STORE[job_id] = updated
    JOB_RETRIES_TOTAL.inc()
    logger.info(f"job_retried job_id={job_id}")
    return updated


@app.get("/registry/services", response_model=list[RegistryServiceResponse])
def list_registry_services(db: Session = Depends(get_db)) -> list[RegistryService]:
    return db.query(RegistryService).order_by(RegistryService.id.asc()).all()


@app.post("/registry/services", response_model=RegistryServiceResponse, status_code=201)
def create_registry_service(payload: RegistryServiceCreate, db: Session = Depends(get_db)) -> RegistryService:
    service = RegistryService(**payload.model_dump())
    db.add(service)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="service_name already exists") from exc
    db.refresh(service)
    REGISTRY_UPSERTS_TOTAL.inc()
    logger.info(f"registry_service_created id={service.id} service_name={service.service_name}")
    return service


@app.patch("/registry/services/{service_id}", response_model=RegistryServiceResponse)
def patch_registry_service(
    service_id: int,
    payload: RegistryServicePatch,
    db: Session = Depends(get_db),
) -> RegistryService:
    service = db.get(RegistryService, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="registry service not found")

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(service, field, value)

    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="service_name already exists") from exc

    db.refresh(service)
    REGISTRY_UPSERTS_TOTAL.inc()
    logger.info(f"registry_service_updated id={service.id} service_name={service.service_name}")
    return service


@app.get("/healthz", response_model=ServiceHealth)
def healthz() -> ServiceHealth:
    return ServiceHealth(service_name="orchestrator-api", ok=True, gpu={}, version="0.4.0")


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
