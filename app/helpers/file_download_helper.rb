module FileDownloadHelper
  def filename_for_download(original_filename)
    filename_prefix = ChorusConfig.instance['file_download.name_prefix'].try(:[], 0..19) || ""
    filename_prefix.gsub!(/"/,'')
    [filename_prefix, original_filename].join
  end
end