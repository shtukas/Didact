
# encoding: UTF-8

class Config

    # Config::pathToLocalDataBankStargate()
    def self.pathToLocalDataBankStargate()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate"
    end

    # Config::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::pathToLocalDataBankStargate()}/config.json"))
        config[key]
    end

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::starlightCommsLine()
    def self.starlightCommsLine()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/multi-instance-shared2/commsline"
    end

    # Config::orbital()
    def self.orbital()
        "#{Config::userHomeDirectory()}/Galaxy/Orbital"
    end
end

class SharedConfig

    # SharedConfig::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::pathToLocalDataBankStargate()}/multi-instance-shared2/shared-config.json"))
        config[key]
    end
end