class SourceInstancesController < JSONAPI::ResourceController
  # before_action :set_source_instance, only: [:show, :edit, :update, :destroy]

  # GET /source_instances
  # GET /source_instances.json
#   def index
#     @source_instances = SourceInstance.all
#   end
#
#   # GET /source_instances/1
#   # GET /source_instances/1.json
#   def show
#   end
#
#   # GET /source_instances/new
#   def new
#     @source_instance = SourceInstance.new
#   end
#
#   # GET /source_instances/1/edit
#   def edit
#   end
#
#   # POST /source_instances
#   # POST /source_instances.json
#   def create
#     @source_instance = SourceInstance.new(source_instance_params)
#
#     respond_to do |format|
#       if @source_instance.save
#         format.html { redirect_to @source_instance, notice: 'Source instance was successfully created.' }
#         format.json { render :show, status: :created, location: @source_instance }
#       else
#         format.html { render :new }
#         format.json { render json: @source_instance.errors, status: :unprocessable_entity }
#       end
#     end
#   end
#
#   # PATCH/PUT /source_instances/1
#   # PATCH/PUT /source_instances/1.json
#   def update
#     respond_to do |format|
#       if @source_instance.update(source_instance_params)
#         format.html { redirect_to @source_instance, notice: 'Source instance was successfully updated.' }
#         format.json { render :show, status: :ok, location: @source_instance }
#       else
#         format.html { render :edit }
#         format.json { render json: @source_instance.errors, status: :unprocessable_entity }
#       end
#     end
#   end
#
#   # DELETE /source_instances/1
#   # DELETE /source_instances/1.json
#   def destroy
#     @source_instance.destroy
#     respond_to do |format|
#       format.html { redirect_to source_instances_url, notice: 'Source instance was successfully destroyed.' }
#       format.json { head :no_content }
#     end
#   end
#
#   private
#     # Use callbacks to share common setup or constraints between actions.
#     def set_source_instance
#       @source_instance = SourceInstance.find(params[:id])
#     end
#
#     # Never trust parameters from the scary internet, only allow the white list through.
#     def source_instance_params
#       params.require(:source_instance).permit(:source_id)
#     end
end
