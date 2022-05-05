
# encoding: UTF-8

class InfinityFileSystemCheck

    # InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(object, nx111)
    def self.fsckExitAtFirstFailureIamValue(object, nx111)
        if !Nx111::iamTypes().include?(nx111["type"]) then
            puts "object has an incorrect iam value type".red
            puts JSON.pretty_generate(object).red
            exit
        end
        if nx111["type"] == "navigation" then
            return
        end
        if nx111["type"] == "log" then
            return
        end
        if nx111["type"] == "description-only" then
            return
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            if InfinityDatablobs_PureDrive::getBlobOrNull(nhash).nil? then
                puts "object, could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            status = AionFsck::structureCheckAionHash(InfinityElizabethPureDrive.new(), rootnhash)
            if !status then
                puts "object, could not validate aion-point".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        if nx111["type"] == "unique-string" then
            return
        end
        if nx111["type"] == "primitive-file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit
            end
            parts.each{|nhash|
                blob = InfinityDatablobs_PureDrive::getBlobOrNull(nhash)
                next if blob
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, nhash not found: #{nhash}".red
                exit
            }
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            status = File.exists?(location)
            if !status then
                puts "could not find location".red
                puts JSON.pretty_generate(object).red
                exit
            end
            status = LucilleCore::locationsAtFolder(location).size == 1
            if !status then
                puts "expecting only one file at location".red
                puts JSON.pretty_generate(object).red
                exit
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{nx111})"
    end

    # InfinityFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item)
    def self.fsckExitAtFirstFailureLibrarianMikuObject(item)
        if item["mikuType"] == "Nx60" then
            return
        end
        if item["mikuType"] == "Nx100" then
            if item["iam"].nil? then
                puts "Nx100 has not iam value".red
                puts JSON.pretty_generate(item).red
                exit
            end
            puts JSON.pretty_generate(item["iam"])
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxAttachment" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxDated" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFloat" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxFyre" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "TxInbox2" then
            if item["aionrootnhash"] then
                # Librarian3ElizabethXCache is correct here
                status = AionFsck::structureCheckAionHash(Librarian3ElizabethXCache.new(), item["aionrootnhash"])
                if !status then
                    puts "aionrootnhash does not validate".red
                    puts JSON.pretty_generate(item).red
                    exit
                end
            end
            return
        end
        if item["mikuType"] == "TxTodo" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end
        if item["mikuType"] == "Wave" then
            InfinityFileSystemCheck::fsckExitAtFirstFailureIamValue(item, item["iam"])
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end

    # InfinityFileSystemCheck::fsck_OnePreciseObjectCheckPerFsckRunHash_ExitAtFirstFailure()
    def self.fsck_OnePreciseObjectCheckPerFsckRunHash_ExitAtFirstFailure()

        puts "For every fsck run hash, we check every object and then each of the object's next versions"

        if LucilleCore::askQuestionAnswerAsBoolean("reset fsck run hash ? ", false) then
            XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F51", SecureRandom.hex)
        end

        fsckrunhash = XCache::getOrNull("1A07231B-8535-499B-BB2C-89A4EB429F51")

        if fsckrunhash.nil? then
            fsckrunhash = SecureRandom.hex
            XCache::set("1A07231B-8535-499B-BB2C-89A4EB429F51", fsckrunhash)
        end

        Librarian7ObjectsInfinity::objects()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .reverse
            .each{|item|
                if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
                    puts "Interrupted after missing canary file.".green
                    return 
                end
                objectKey =  "#{fsckrunhash}:#{JSON.generate(item)}"
                next if XCache::flagIsTrue(objectKey)
                puts JSON.pretty_generate(item)
                InfinityFileSystemCheck::fsckExitAtFirstFailureLibrarianMikuObject(item)
                XCache::setFlagTrue(objectKey)
            }

        puts "Fsck completed successfully".green
    end

    # InfinityFileSystemCheck::fsckExitAtFirstFailure()
    def self.fsckExitAtFirstFailure()
        InfinityFileSystemCheck::fsck_OnePreciseObjectCheckPerFsckRunHash_ExitAtFirstFailure()
    end
end
