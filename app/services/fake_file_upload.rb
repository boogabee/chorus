class FakeFileUpload < StringIO
  attr_accessor :content_type, :original_filename
end