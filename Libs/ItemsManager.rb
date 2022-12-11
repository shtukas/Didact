
class ItemsManager

    # ItemsManager::filepathForUUID(foldername, uuid)
    def self.filepathForUUID(foldername, uuid)
        "#{Config::pathToDataCenter()}/#{foldername}/#{uuid}.Nx5"
    end

    # ItemsManager::filepath2(foldername, uuid)
    def self.filepath2(foldername, uuid)
        "#{Config::pathToDataCenter()}/#{foldername}/#{uuid}.json"
    end

    # ItemsManager::items(foldername)
    def self.items(foldername)
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/#{foldername}")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
            .map{|filepath|
                # We are doing this during the transition period
                filepath2 = filepath.gsub(".Nx5", "json")
                if File.exists?(filepath2) then
                    JSON.parse(IO.read(filepath2))
                else
                    Nx5Ext::readFileAsAttributesOfObject(filepath)
                end
            }
    end

    # ItemsManager::commitItem(foldername, item)
    def self.commitItem(foldername, item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = ItemsManager::filepath2(foldername, item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # ItemsManager::getOrNull(foldername, uuid)
    def self.getOrNull(foldername, uuid)
        filepath = ItemsManager::filepathForUUID(foldername, uuid)
        filepath2 = filepath.gsub(".Nx5", ".json")
        if File.exists?(filepath2) then
            return JSON.parse(IO.read(filepath2))
        end
        if File.exists?(filepath) then
            return Nx5Ext::readFileAsAttributesOfObject(filepath)
        end
        nil
    end

    # ItemsManager::destroy(foldername, uuid)
    def self.destroy(foldername, uuid)
        filepath = ItemsManager::filepathForUUID(foldername, uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        filepath2 = filepath.gsub(".Nx5", ".json")
        if File.exists?(filepath2) then
            FileUtils.rm(filepath2)
        end
        ItemToCx22::garbageCollection(uuid)
    end

end
