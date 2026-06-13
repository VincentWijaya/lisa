class MenusController < ApplicationController
  before_action :authenticate_user!

  MENU_KEYS = %w[
    bank_darah
    mikrobiologi
    patologi_anatomi
    inventori
    monitor_qc
    laporan
  ].freeze

  def show
    @menu_key = params.fetch(:menu_key)
    raise ActionController::RoutingError, "Not Found" unless MENU_KEYS.include?(@menu_key)

    @page_title = t("menus.#{@menu_key}.title")
  end
end
