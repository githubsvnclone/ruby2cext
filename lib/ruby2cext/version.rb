
module Ruby2CExtension

	VERSION = "0.2.0"

	FULL_VERSION_STRING = "Ruby2CExtension #{VERSION} (Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}))"

	SUPPORTED_RUBY_VERSIONS = {
		"1.8.4" => "2005-12-24",
		"1.8.5" => "2006-08-25",
	}

	if (date = SUPPORTED_RUBY_VERSIONS[RUBY_VERSION])
		unless RUBY_RELEASE_DATE == date
			warn "Warning: Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) is not the official release of Ruby #{RUBY_VERSION}, there might be problems"
		end
	else
		warn "Warning: Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) is not supported by Ruby2CExtension #{VERSION}"
	end

end