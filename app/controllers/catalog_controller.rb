# rubocop:disable ClassLength
class CatalogController < ApplicationController
  layout 'application_with_sidebar'

  before_action :set_equipment_model, only:
    [:add_to_cart, :remove_from_cart, :edit_cart_item]
  skip_before_action :authenticate_user!, unless: :guests_disabled?

  # --------- before filter methods --------- #

  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    logger.error("Attempt to add invalid equipment model #{params[:id]}")
    flash[:notice] = 'Invalid equipment_model'
    redirect_to root_path
  end

  # --------- end before filter methods --------- #

  def index
    @reserver_id = session[:cart].reserver_id
    prepare_pagination
    prepare_catalog_index_vars
  end

  def add_to_cart
    change_cart(:add_item, @equipment_model)
  end

  def edit_cart_item
    change_cart(:edit_cart_item, @equipment_model, params[:quantity].to_i)
  end

  def update_user_per_cat_page
    unless params[:items_per_page].blank?
      session[:items_per_page] = params[:items_per_page]
    end
    respond_to do |format|
      format.html { redirect_to root_path }
      format.js { render action: 'cat_pagination' }
    end
  end

  def submit_form # rubocop:disable MethodLength, AbcSize
    flash.clear
    begin
      # set the start and end date to updated values
      cart.start_date = Date.strptime(params[:form][:start_date], '%m/%d/%Y')
      cart.due_date = Date.strptime(params[:form][:due_date], '%m/%d/%Y')
      cart.fix_due_date
    rescue ArgumentError
      flash[:error] = 'Please enter a valid start or due date.'
    end

    # get soft blackout notices
    notices = []
    notices << Blackout.get_notices_for_date(cart.start_date, :soft)
    notices << Blackout.get_notices_for_date(cart.due_date, :soft)
    notices = notices.reject(&:blank?).to_sentence
    notices += "\n" unless notices.blank?
    # update all the items in the cart
    (0..(params[:quantity].count - 1)).each do |i|
      @quantity = params[:quantity].values[i].to_i
      @model_id = params[:quantity].keys[i].to_i
      # make sure the quantity changed before looking for Models
      if cart.items[@model_id] != @quantity
        @equipment_model = EquipmentModel.find(@model_id)
        cart.send(:edit_cart_item, @equipment_model, @quantity)
      end
    end

    # validate
    errors = cart.validate_all
    # don't over-write flash if invalid date was set above
    flash[:error] ||= notices + "\n" + errors.join("\n")
    flash[:notice] = 'Reservation updated.'
    redirect_to new_reservation_path
  end

  def search
    if params[:query].blank?
      redirect_to(root_path) && return
    else
      @equipment_model_results =
        EquipmentModel.active.catalog_search(params[:query])
      @category_results = Category.catalog_search(params[:query])
      @equipment_item_results =
        EquipmentItem.catalog_search(params[:query])
      prepare_catalog_index_vars(@equipment_model_results)
      render('search_results') && return
    end
  end

  def deactivate
    if params[:deactivation_cancelled]
      flash[:notice] = 'Deactivation cancelled.'
      redirect_to categories_path
    elsif params[:deactivation_confirmed]
      super
    else
      flash[:error] = 'Oops, something went wrong.'
      redirect_to categories_path
    end
  end

  private

  # this method is called to either add or remove an item from the cart
  # it takes either :add_item or :remove_item as an action variable and adds
  # or removes the equipment_model set from params{} in the before_filter.
  # Finally, it renders the root page and runs the javascript to update the
  # cart (or displays the appropriate errors)
  def change_cart(action, item, quantity = nil)
    cart.send(action, item, quantity)
    errors = cart.validate_all
    flash[:error] = errors.join("\n")
    flash[:notice] = 'Cart updated.'

    respond_to do |format|
      format.html { redirect_to root_path }
      format.js do
        # this isn't necessary for EM show page updates but not sure how to
        # check for catalog views since it's always in the catalog controller
        prepare_catalog_index_vars([item])
        @item = item
        render template: 'cart_js/update_cart'
      end
    end
  end

  def prepare_pagination
    array = []
    array << params[:items_per_page].to_i
    array << session[:items_per_page].to_i
    array << @app_configs.default_per_cat_page
    array << 10
    items_per_page = array.reject { |a| a.blank? || a == 0 }.first
    # assign items per page to the passed params, the default or 10
    # depending on if they exist or not
    @per_page_opts = [10, 20, 25, 30, 50].unshift(items_per_page).uniq
    session[:items_per_page] = items_per_page
  end
end
