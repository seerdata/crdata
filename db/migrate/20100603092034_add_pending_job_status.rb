class AddPendingJobStatus < ActiveRecord::Migration
  def self.up
    execute <<-UPMIG
      CREATE OR REPLACE FUNCTION job_status_management() RETURNS trigger AS $job_status_management$
          BEGIN
              -- A job cannot be submitted twice, nor it can be run twice
              IF NEW.jobs_queue_id IS NOT NULL AND OLD.jobs_queue_id IS NOT NULL AND (NEW.jobs_queue_id <> OLD.jobs_queue_id) THEN
                  RAISE EXCEPTION 'cannot resubmit a job once it''s in a queue';
              END IF;
              IF NEW.processing_node_id IS NOT NULL AND OLD.processing_node_id IS NOT NULL AND (NEW.processing_node_id <> OLD.processing_node_id) THEN
                  RAISE EXCEPTION 'cannot run a job once it''s in running mode';
              END IF;

              -- Protect against unwanted status change
              IF OLD.status <> NEW.status AND OLD.status IS NULL AND NEW.status <> 'new' THEN
                  RAISE EXCEPTION 'invalid status transition from';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'new' AND NEW.status <> 'submitted' AND NEW.status <> 'cancelled' AND NEW.status <> 'pending' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'submitted' AND NEW.status <> 'running' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'running' AND NEW.status <> 'done' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND (OLD.status = 'done' OR OLD.status = 'cancelled') AND (NEW.status <> OLD.status) THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'pending' AND NEW.status <> 'done' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;

              RETURN NEW;
          END;

      $job_status_management$ LANGUAGE plpgsql;
    UPMIG
  end

  def self.down
     execute <<-UPMIG
      CREATE OR REPLACE FUNCTION job_status_management() RETURNS trigger AS $job_status_management$
          BEGIN
              -- A job cannot be submitted twice, nor it can be run twice
              IF NEW.jobs_queue_id IS NOT NULL AND OLD.jobs_queue_id IS NOT NULL AND (NEW.jobs_queue_id <> OLD.jobs_queue_id) THEN
                  RAISE EXCEPTION 'cannot resubmit a job once it''s in a queue';
              END IF;
              IF NEW.processing_node_id IS NOT NULL AND OLD.processing_node_id IS NOT NULL AND (NEW.processing_node_id <> OLD.processing_node_id) THEN
                  RAISE EXCEPTION 'cannot run a job once it''s in running mode';
              END IF;

              -- Protect against unwanted status change
              IF OLD.status <> NEW.status AND OLD.status IS NULL AND NEW.status <> 'new' THEN
                  RAISE EXCEPTION 'invalid status transition from';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'new' AND NEW.status <> 'submitted' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'submitted' AND NEW.status <> 'running' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND OLD.status = 'running' AND NEW.status <> 'done' AND NEW.status <> 'cancelled' THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              IF OLD.status <> NEW.status AND (OLD.status = 'done' OR OLD.status = 'cancelled') AND (NEW.status <> OLD.status) THEN
                  RAISE EXCEPTION 'invalid status transition';
              END IF;
              
              RETURN NEW;
          END;
      $job_status_management$ LANGUAGE plpgsql;
    UPMIG
  end
end
