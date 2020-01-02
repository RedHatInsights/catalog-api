### This will go away. The logic in here would go into the Inisghts Common Status Controller
class StatusController < ActionController::API
  def health
    @output = {}

    if db_up?
      @output[:status] = migration_context.needs_migration? ? "warn" : "pass"
      @output[:database_status] = "up"
    else
      @output[:status] = "fail"
      @output[:database_status] = "down"
    end

    @output[:pending_migrations] = pending_migrations

    render :json => @output, :status => status
  end

  private

  def migration_context
    ActiveRecord::Base.connection.migration_context
  end

  def pending_migrations
    migration_context.migrations_status.collect(&:first).count("down")
  end

  def status
    case @output[:status]
    when "fail"
      :internal_server_error
    when "warn"
      :partial_content
    else
      :ok
    end
  end

  def db_up?
    PG::Connection.ping(ENV['DATABASE_URL']) == PG::Connection::PQPING_OK
  end
end

###### The above will change to this:
# class StatusController < Insights::API::Common::StatusController; end
