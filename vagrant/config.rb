require 'yaml'

def getConfig(configFolder)
	baseConfig = YAML.load_file("#{configFolder}/config.yml")
	configFile = "#{configFolder}/config_override.yml"
	overrideConfig = { }

	overrideConfig = YAML.load_file(configFile) if File.file?(configFile)

	overrideConfig.deep_merge!(baseConfig)
end
