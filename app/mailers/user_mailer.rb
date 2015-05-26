class UserMailer < ActionMailer::Base
  # Workaround so that RSpec start-up doesn't fail.
  # TODO: Have RSpec initialize AppConfig with configuration.
  add_template_helper(ApplicationHelper)
  if AppConfig.first.nil?
    default from: 'no-reply@reservations.app'
  else
    default from: AppConfig.get(:admin_email), cc: AppConfig.get(:admin_email)
  end

  # checks the status of the current reservation and sends the appropriate email
  # force forces a check out receipt to be sent OR an approved request notification,
  # depending on the reservation status
  def reservation_status_update(reservation, force = false) # rubocop:disable all
    set_app_config

    @reservation = reservation
    @status = @reservation.human_status

    return if !force && @status == 'returned' && @reservation.overdue &&
              @reservation.equipment_model.late_fee == 0

    return if force && (@reservation.checked_out.nil? && !@reservation.approved?)

    if force
      if @reservation.checked_out
        @status = 'checked out'
      else
        @status = 'request approved'
      end
    end

    if @status == 'reserved'
      # we only send emails for reserved reservations if it was a request
      @status = 'request approved'
    end

    status_formatted = @status.sub('_', ' ').split.map(&:capitalize) * ' '

    mail(to: @reservation.reserver.email,
         subject: '[Reservations] ' \
                  "#{@reservation.equipment_model.name.capitalize} "\
                  " #{status_formatted}")
  end

  private

  def set_app_config
    @app_configs ||= AppConfig.first
  end
end
