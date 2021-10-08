
# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Quarks.rb"

=begin

Specs:

Quarks (NxA001, NxA002, etc) are immutable data carriers. They are self contained KV stores used by Catalyst and Nyx.

### Filenaming

```
[id].nxaxiom-[variant]
```

... where [id] should be reasonably unique and [variant] is a 3 digit number.

### File structure

Each variant is its own file format.

001 (Text Carrier)
    - Embedded KV
    - data (text) is stored in key "text-4e1e-aef4-58165e46651c"

002 (URL)
    - Embedded KV
    - URL is stored in key "url-45ed-960e-c23d39bb64ce"

003 (aion-point)
    - Embedded KV
    - Root nhash is stored in "nhash-c4ae0383-8a1f"
    - File binary blobs are stored agsint their nhash

=end

require 'find'

require 'fileutils'

require 'daybreak'
# https://propublica.github.io/daybreak/

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, nhash, blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

# ------------------------------------------------------------------------

class QsElizabeth

    def initialize(db)
        @db = db
    end

    def commitBlob(blob)
        CoreData::putBlob(blob)

        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        @db[nhash] = blob
        @db.flush
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = CoreData::getBlobOrNull(nhash)
        return blob if blob

        blob = @db[nhash]
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?

        CoreData::putBlob(blob)
        
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class QsUtils

    # QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
    def self.findAxiomFilepathByIdOrNull(repositoryRoot, id)
        Find.find(repositoryRoot) do |location|
            next if !File.file?(location)
            next if !(File.basename(location)[-12, 9] == ".nxaxiom-") # 123456789.nxaxiom-001
            next if !File.basename(location).start_with?(id)
            return location
        end
        nil
    end

    # QsUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # QsUtils::destroy(repositoryRoot, id)
    def self.destroy(repositoryRoot, id)
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return if filepath.nil?
        FileUtils.rm(filepath)
    end
end

class NxA001

    # NxA001::make(fileParentFolder: String, id: String, text: String): AxiomId
    def self.make(fileParentFolder, id, text)
        filename = "#{id}.nxaxiom-001"
        filepath = "#{fileParentFolder}/#{filename}"
        db = Daybreak::DB.new filepath
        db["text-4e1e-aef4-58165e46651c"] = text
        db.close
        id
    end

    # NxA001::accessWithOptionToEdit(repositoryRoot: String, id: String)
    def self.accessWithOptionToEdit(repositoryRoot, id)
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return if filepath.nil?
        db = Daybreak::DB.new filepath
        text = db["text-4e1e-aef4-58165e46651c"]
        db.close
        text2 = QsUtils::editTextSynchronously(text)
        if text2 != text then
            db = Daybreak::DB.new filepath
            db["text-4e1e-aef4-58165e46651c"] = text2
            db.close
        end
    end

    # NxA001::destroy(repositoryRoot: String, id: String): Boolean
    def self.destroy(repositoryRoot, id)
        QsUtils::destroy(repositoryRoot, id)
    end
end

class NxA002

    # NxA002::make(fileParentFolder: String, id: String, url: String): AxiomId
    def self.make(fileParentFolder, id, url)
        filename = "#{id}.nxaxiom-002"
        filepath = "#{fileParentFolder}/#{filename}"
        db = Daybreak::DB.new filepath
        db["url-45ed-960e-c23d39bb64ce"] = url
        db.close
        id
    end

    # NxA002::accessWithOptionToEdit(repositoryRoot: String, id: String)
    def self.accessWithOptionToEdit(repositoryRoot, id)
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return if filepath.nil?
        db = Daybreak::DB.new filepath
        url = db["url-45ed-960e-c23d39bb64ce"]
        db.close
        system("open -a Safari '#{url}'")
    end

    # NxA002::destroy(repositoryRoot: String, id: String): Boolean
    def self.destroy(repositoryRoot, id)
        QsUtils::destroy(repositoryRoot, id)
    end
end

class NxA003

    # NxA003::make(fileParentFolder: String, id: String, location: String): AxiomId
    def self.make(fileParentFolder, id, location)
        filename = "#{id}.nxaxiom-003"
        filepath = "#{fileParentFolder}/#{filename}"
        db = Daybreak::DB.new filepath
        operator = QsElizabeth.new(db)
        nhash = AionCore::commitLocationReturnHash(operator, location)
        db["nhash-c4ae0383-8a1f"] = nhash
        db.close
        id
    end

    # NxA003::accessWithOptionToEdit(repositoryRoot: String, id: String)
    def self.accessWithOptionToEdit(repositoryRoot, id)
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return if filepath.nil?
        db = Daybreak::DB.new filepath
        operator = QsElizabeth.new(db)
        nhash = db["nhash-c4ae0383-8a1f"]
        AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
        db.close
        # TODO: implement the option to edit
    end

    # NxA003::destroy(repositoryRoot: String, id: String): Boolean
    def self.destroy(repositoryRoot, id)
        QsUtils::destroy(repositoryRoot, id)
    end
end

class Quarks

    # The AxiomId is echoed if an object was created otherwise null
    # This matches the way clients have been using the function
    # Quarks::interactivelyCreateNewAxiom_EchoIdOrNull(fileParentFolder: String, id: String) : AxiomId or null
    def self.interactivelyCreateNewAxiom_EchoIdOrNull(fileParentFolder, id)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("axiom type", ["text", "url", "location"])
        return nil if type.nil?
        if type == "text" then
            text = QsUtils::editTextSynchronously("")
            return NxA001::make(fileParentFolder, id, text)
        end

        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return NxA002::make(fileParentFolder, id, url)
        end

        if type == "location" then
            locationNameOnDesktop = LucilleCore::askQuestionAnswerAsString("location of desktop (empty to abort): ")
            return nil if locationNameOnDesktop == ""
            return NxA003::make(fileParentFolder, id, "/Users/pascal/Desktop/#{locationNameOnDesktop}")
        end

        raise "[67d592dd-162d-46b5-b26c-ead4345e4e1e, type: #{type}]"
    end

    # Quarks::contentTypeOrNull(repositoryRoot: String, id: String)
    def self.contentTypeOrNull(repositoryRoot, id)
        return nil if id.nil?
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return nil if filepath.nil?
        if filepath[-3, 3] == "001" then
            return "text"
        end
        if filepath[-3, 3] == "002" then
            return "url"
        end
        if filepath[-3, 3] == "003" then
            return "aion-point"
        end
        raise "2af3e337-eddd-4203-9a28-21ea06655c83: non standard variant for (repositoryRoot: #{repositoryRoot}, id: #{id}, filepath: #{filepath})"
    end

    # Quarks::accessWithOptionToEdit(repositoryRoot: String, id: String)
    def self.accessWithOptionToEdit(repositoryRoot, id)
        return if id.nil?
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        return if filepath.nil?
        if filepath[-3, 3] == "001" then
            NxA001::accessWithOptionToEdit(repositoryRoot, id) # text
            return
        end
        if filepath[-3, 3] == "002" then
            NxA002::accessWithOptionToEdit(repositoryRoot, id) # url
            return
        end
        if filepath[-3, 3] == "003" then
            NxA003::accessWithOptionToEdit(repositoryRoot, id) # aion-point
            return
        end
        raise "2201ddcd-cb33-4faf-9388-e4ebb6e7f28f: non standard variant for (repositoryRoot: #{repositoryRoot}, id: #{id}, filepath: #{filepath})"
    end

    # Quarks::destroy(repositoryRoot: String, id: String | null): Boolean
    def self.destroy(repositoryRoot, id)
        return if id.nil?
        QsUtils::destroy(repositoryRoot, id)
    end

    # Quarks::fsck(repositoryRoot: String, id: String) : Boolean
    def self.fsck(repositoryRoot, id)
        return true if id.nil?
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        if filepath.nil? then
            puts "Could not find filepath for (repositoryRoot: #{repositoryRoot}, id: #{id})".red
            LucilleCore::pressEnterToContinue()
            return false
        end
        if filepath[-3, 3] == "001" then
            return true
        end
        if filepath[-3, 3] == "002" then
            return true
        end
        if filepath[-3, 3] == "003" then
            db = Daybreak::DB.new filepath
            operator = QsElizabeth.new(db)
            nhash = db["nhash-c4ae0383-8a1f"]
            if nhash.nil? then
                db.close
                puts "Looking at (repositoryRoot: #{repositoryRoot}, id: #{id})".red
                puts "Could not find value for key [nhash-c4ae0383-8a1f]".red
                LucilleCore::pressEnterToContinue()
                return false
            end
            status = AionFsck::structureCheckAionHash(operator, nhash)
            db.close
            return status
        end
        raise "4ecddee2-0d4c-4e26-ab41-c6da2fd91b4e: non standard variant for (repositoryRoot: #{repositoryRoot}, id: #{id}, filepath: #{filepath})"
    end

    # Quarks::migration(repositoryRoot: String, id: String)
    def self.migration(repositoryRoot, id)
        return if id.nil?
        filepath = QsUtils::findAxiomFilepathByIdOrNull(repositoryRoot, id)
        if filepath.nil? then
            puts "Could not find filepath for (repositoryRoot: #{repositoryRoot}, id: #{id})".red
            LucilleCore::pressEnterToContinue()
            return
        end
        if filepath[-3, 3] == "001" then
            db = Daybreak::DB.new filepath
            puts db["text-4e1e-aef4-58165e46651c"]
            coredataobject = {
                "uuid"  => id,
                "type"  => "text",
                "text"  => db["text-4e1e-aef4-58165e46651c"]
            }
            puts JSON.pretty_generate(coredataobject)
            CoreData::commitObject(coredataobject)
            db.close
            return
        end
        if filepath[-3, 3] == "002" then
            db = Daybreak::DB.new filepath
            puts db["url-45ed-960e-c23d39bb64ce"]
            coredataobject = {
                "uuid"  => id,
                "type"  => "url",
                "url"   => db["url-45ed-960e-c23d39bb64ce"]
            }
            puts JSON.pretty_generate(coredataobject)
            CoreData::commitObject(coredataobject)
            db.close
            return
        end
        if filepath[-3, 3] == "003" then
            db = Daybreak::DB.new filepath
            operator = QsElizabeth.new(db)
            nhash = db["nhash-c4ae0383-8a1f"]
            if nhash.nil? then
                db.close
                puts "Looking at (repositoryRoot: #{repositoryRoot}, id: #{id})".red
                puts "Could not find value for key [nhash-c4ae0383-8a1f]".red
                puts "Did this pass fsck? 🤔".red
                LucilleCore::pressEnterToContinue()
                return
            end
            coredataobject = {
                "uuid"  => id,
                "type"  => "aion-point",
                "nhash" => nhash
            }
            puts JSON.pretty_generate(coredataobject)
            CoreData::commitObject(coredataobject)
            db.close
            status = AionFsck::structureCheckAionHash(operator, nhash)
            db.close
            if !status then
                puts "Looking at (repositoryRoot: #{repositoryRoot}, id: #{id})".red
                puts "nhash: #{nhash}".red
                puts "AionFsck::structureCheckAionHash(operator, nhash) returned false".red
                puts "Did this pass fsck? 🤔".red
                LucilleCore::pressEnterToContinue()
            end
        end
    end
end
