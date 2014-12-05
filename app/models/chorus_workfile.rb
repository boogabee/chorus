class ChorusWorkfile < Workfile
  attr_accessible :versions_attributes, :as => [:default, :create]
  attr_accessible :svg_data, :as => [:create]
  attr_accessible :execution_schema

  alias_attribute :execution_schema, :execution_location

  has_many :versions, :foreign_key => :workfile_id, :class_name => 'WorkfileVersion', :order => 'version_num DESC', :inverse_of => :workfile, :dependent => :destroy
  has_many :drafts, :class_name => 'WorkfileDraft', :foreign_key => :workfile_id

  before_validation :ensure_version_exists, :on => :create, :prepend => true
  before_create :set_execution_schema

  accepts_nested_attributes_for :versions

  def svg_data=(svg_data)
    # Note: This conversion upon assignment depends on the "file_name"
    # being populated--and that file_name is being assigned from the same
    # hash (during build_for)
    # So 'file_name' has to precede 'svg_data' in the params hash
    # providing this.
    transcoder = SvgToPng.new(svg_data)
    versions.build :contents => transcoder.fake_uploaded_file(file_name)
  end

  def build_new_version(user, source_file, message)
    versions.build(
        :owner => user,
        :modifier => user,
        :contents => source_file,
        :version_num => last_version_number + 1,
        :commit_message => message,
    )
  end

  def update_from_params!(params)
    is_upload = params[:file_name].nil?
    is_svg = !params[:svg_data].nil?
    self.resolve_name_conflicts = (is_svg || is_upload)
    save!
  end

  def create_new_version(user, params)
    file = params[:content]
    unless file.respond_to? :original_filename
      file = build_new_file(file_name, file)
      file.content_type = latest_workfile_version.contents_content_type
    end

    Workfile.transaction do
      workfile_version = build_new_version(user, file, params[:commit_message])
      workfile_version.save!
      create_event_for_upgrade(user)
      remove_draft(user)
    end

    reload
  end

  def build_new_file(file_name, content)
    tempfile = Tempfile.new(file_name)
    tempfile.write(content)
    tempfile.close

    ActionDispatch::Http::UploadedFile.new(:filename => file_name, :tempfile => tempfile)
  end

  def remove_draft(user)
    drafts.find_by_owner_id(user.id).try(:destroy)
  end

  def has_draft(current_user)
    !!WorkfileDraft.find_by_owner_id_and_workfile_id(current_user.id, id)
  end

  def entity_type_name
    'workfile'
  end

  def create_event_for_upgrade(user)
    Events::WorkfileUpgradedVersion.by(user).add(
        :workfile => self,
        :workspace => workspace,
        :version_num => latest_workfile_version.version_num,
        :commit_message => latest_workfile_version.commit_message,
        :version_id => latest_workfile_version.id
    )
  end

  private
  def last_version_number
    latest_workfile_version.try(:version_num) || 0
  end

  def init_file_name
    self.file_name ||= versions.first.file_name
    super
  end

  def set_execution_schema
    self.execution_schema = workspace.sandbox if versions.first && versions.first.sql? && !execution_schema
  end

  def ensure_version_exists
    version = versions.first
    unless(version)
      version = versions.build
      file = FakeFileUpload.new
      file.original_filename = file_name
      version.contents = file
    end
    version.owner = owner
    version.modifier = owner
    true
  end

end
