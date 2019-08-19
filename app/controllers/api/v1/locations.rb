module Api
  module V1
    class Locations < Grape::API
      include Api::V1::Defaults
      helpers SessionHelpers

      before do
        error!('Unauthorized', 401) unless require_login!
      end


      #Lets driver look up resources that do no belong to them
      desc "Return a location with a given ID"
      params do
        requires :id, type: String, desc: "ID of the location"
      end
      get "locations/:id", root: :location do
        render Location.find(permitted_params[:id])
      end


      #Returns all locations of the current driver
      desc "Return all locations for a given driver"
      params do
      end
      get "locations" do
        driver = current_driver
        location_ids = LocationRelationship.where(driver_id: driver.id).select("location_id")
        locations = Location.where(id: location_ids)
        render locations
      end


      #Create a location for the current driver
      #Needs address information to create
      desc "Create a new location from a driver"
      params do
        requires :location, type: Hash do
          requires :street , type:String
          requires :city, type:String
          requires :state, type: String
          requires :zip, type: String
        end
      end
      post "locations" do
        driver = current_driver
        location = Location.new
        location.attributes= (params[:location])
        if location.save
          LocationRelationship.create(location_id: location.id, driver_id: driver.id)
          render json: location
        end
      end


      desc "Delete an association between a driver and a location"
      params do
        requires :id, type: String, desc: "ID of location"
      end
      delete 'locations/:id' do
        driver = current_driver
        location = Location.find(permitted_params[:id])
        if location != nil
          LocationRelationship.find_by(location_id: permitted_params[:id],
             driver_id: driver.id).destroy
          #Logic about multiple users using the same location
          if LocationRelationship.where(location: permitted_params[:id]).count == 0
            location.destroy
            return { success:true }
            #Needed to return if successful or not
            # Was just always returning success
          else
            return{success:false}
          end

        end
      end

      #Update a location for a driver
      desc "put a location from a driver"
        params do
          requires :id, type: Integer, desc: "ID of location"
          requires :location, type: Hash do
            optional :street , type:String
            optional :city, type:String
            optional :state, type: String
            optional :zip, type: String
          end
      end
      put "locations/:id" do
        driver = current_driver
        #Find location to change
        old_location = Location.find(params[:id])
        #If location has more than one locationrelationship run code
        #Keeps location from having more than one user
        if LocationRelationship.where(location_id: params[:location][:id]).count > 1
          #Fix for new location creation so id changes
          #Create new location and locationrelationship
          new_location = Location.create(params[:location])
          LocationRelationship.create(location_id: new_location.id, driver_id: driver.id)
          render json: new_location
        else
          #update old location
          old_location.update(params[:location])
          render json: old_location
        end
      end
    end
  end
end
