module Settings
  # Lets the signed-in user turn TOTP two-factor authentication on and off.
  # Everything acts on Current.user (there are no ids in the URL), so one
  # user can never see or change another user's second factor.
  #
  # Setting up: `new` generates a secret, keeps it in the (encrypted) Rails
  # session and shows it as a QR code; `create` saves it only once a valid
  # code proves the authenticator works, then shows the recovery codes once.
  class TwoFactorsController < ApplicationController
    PENDING_SECRET = :pending_otp_secret

    require_sudo except: :show
    rate_limit to: 10, within: 3.minutes, only: %i[ create destroy ], with: -> {
      redirect_to settings_two_factor_path, alert: "Try again later."
    }

    before_action :redirect_if_enabled, only: %i[ new create ]

    def show
    end

    def new
      session[PENDING_SECRET] ||= User.generate_otp_secret
      load_setup
    end

    def create
      secret = session[PENDING_SECRET]
      return redirect_to(new_settings_two_factor_path) if secret.blank?

      if (@recovery_codes = Current.user.enable_two_factor!(secret, params[:code]))
        session.delete(PENDING_SECRET)
        response.headers["Cache-Control"] = "no-store"
        flash.now[:notice] = "Two-factor authentication is on."
        render :recovery_codes
      else
        load_setup
        flash.now[:alert] = "That code didn't match. Check your authenticator app and try again."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      unless Current.user.two_factor_enabled?
        return redirect_to(settings_two_factor_path)
      end

      if Current.user.verify_two_factor(params[:code])
        Current.user.disable_two_factor!
        redirect_to settings_two_factor_path, notice: "Two-factor authentication is off."
      else
        flash.now[:alert] = "That code didn't match. Enter a code from your authenticator app or a recovery code."
        render :show, status: :unprocessable_entity
      end
    end

    private
      def redirect_if_enabled
        redirect_to settings_two_factor_path if Current.user.two_factor_enabled?
      end

      def load_setup
        @secret = session[PENDING_SECRET]
        @provisioning_uri = Current.user.otp_provisioning_uri(@secret)
      end

      # POST/DELETE can't be replayed after confirming the password.
      def sudo_return_to
        action_name == "new" ? new_settings_two_factor_path : settings_two_factor_path
      end
  end
end
