class DriversController < ApplicationController

  before_action :authenticate_user!
  layout "administration"

  def new
    @driver = Driver.new
  end

  def show
    @driver = Driver.find(params[:id])
    @vehicle = Vehicle.all
    @location_ids = LocationRelationship.where(driver_id: params[:id]).ids
    @locations = Location.where(id: @location_ids)

  end

  def index
    if params[:application_state]== "pending"
      @drivers =Driver.where(:application_state =>"pending").order(last_name: :desc)
    elsif params[:application_state]== "approved"
      @drivers =Driver.where(:application_state =>"approved").order(last_name: :desc)
    else
      @drivers = Driver.order(last_name: :desc)
    end
    @drivers = Kaminari.paginate_array(@drivers).page(params[:page]).per(10)
    @vehicle = Vehicle.all
  end

  def ascending_sort
    @drivers = Driver.order(:last_name)
    @drivers = Kaminari.paginate_array(@drivers).page(params[:page]).per(10)
  end

  def create
    @driver = Driver.new(driver_params)
    generated_password = Devise.friendly_token.first(8)
    @driver.password = generated_password
    @driver.password_confirmation = generated_password
    @driver.organization_id = current_user.organization_id

    if @driver.save
      flash.notice = "The driver information has been saved"
      redirect_to @driver
    else
      render 'new'
    end
  end

  def edit
    @driver = Driver.find(params[:id])
  end

  def update
    @driver = Driver.find(params[:id])

    if @driver.update(driver_params)
      flash.notice = "The driver information has been updated"
      redirect_to @driver
    else
      render 'edit'
    end
  end

  def destroy
    @driver = Driver.find(params[:id])
    @driver.destroy

    redirect_to drivers_path
  end

  #Method to Accept application
  def accept
   @driver = Driver.find(params[:driver_id])
   @driver.update(application_state: "approved")
   redirect_to driver_path(params[:driver_id])
  end

  #Method to Reject application
  def reject
    @driver = Driver.find(params[:driver_id])
    @driver.update(application_state: "rejected")
    redirect_to driver_path(params[:driver_id])
  end

  #change background_check to true
  def pass
    @driver = Driver.find(params[:driver_id])
    @driver.update(background_check: true)
    redirect_to driver_path(params[:driver_id])
  end

  #change background_check to false
  def fail
    @driver = Driver.find(params[:driver_id])
    @driver.update(background_check: false)
    redirect_to driver_path(params[:driver_id])
  end


  private
  def driver_params
    params.require(:driver).permit(:first_name, :last_name, :phone, :email, :address, :car_make, :car_model, :car_color)
  end
end
