
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::ensureAttribute(item, attname, type)
    def self.ensureAttribute(item, attname, type)
        if item[attname].nil? then
            raise "Missing attribute #{attname} in #{JSON.pretty_generate(item)}"
        end
        if type.nil? then
            return
        end
        if type == "Number" then
            types = ["Integer", "Float"]
        else
            types = [type]
        end
        if !types.include?(item[attname].class.to_s) then
            raise "Incorrect attribute type for #{attname} in #{JSON.pretty_generate(item)}, expected: #{type}, found: #{item[attname].class.to_s}"
        end
    end

    # FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, verbose)
    def self.fsck_aion_point_rootnhash(rootnhash, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_aion_point_rootnhash(#{rootnhash}, #{verbose})"
        end
        AionFsck::structureCheckAionHashRaiseErrorIfAny(DatablobStoreElizabeth.new(), rootnhash)
    end

    # FileSystemCheck::fsck_Nx113(item, verbose)
    def self.fsck_Nx113(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Nx113(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Nx113" then
            raise "Incorrect Miku type for function"
        end

        if item["type"].nil? then
            raise "Nx113 doesn't have a type"
        end

        type = item["type"]

        if type == "text" then
            return
        end

        if type == "url" then
            return
        end

        if type == "file" then
            if item["dottedExtension"].nil? then
                 raise "dottedExtension is not defined on #{item}"
            end
            if item["nhash"].nil? then
                 raise "nhash is not defined on #{item}"
            end
            if item["parts"].nil? then
                 raise "parts is not defined on #{item}"
            end
            dottedExtension  = item["dottedExtension"]
            nhash            = item["nhash"]
            parts            = item["parts"]
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, verbose)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
            return
        end

        if type == "aion-point" then
            if item["rootnhash"].nil? then
                 raise "rootnhash is not defined on #{item}"
            end
            rootnhash = item["rootnhash"]
            FileSystemCheck::fsck_aion_point_rootnhash(rootnhash, verbose)
            return
        end

        if type == "Dx8Unit" then
            return
        end

        if type == "unique-string" then
            return
        end

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(item)}, #{verbose})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsck_NxWTimeCommitment(item, verbose)
    def self.fsck_NxWTimeCommitment(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_NxWTimeCommitment(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "NxWTimeCommitment" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
        FileSystemCheck::ensureAttribute(item, "ax39", "Hash")
    end

    # FileSystemCheck::fsck_Dx33(item, verbose)
    def self.fsck_Dx33(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Dx33(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Dx33" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")

        FileSystemCheck::ensureAttribute(item, "unitId", "String")
    end

    # FileSystemCheck::fsck_NxNode(item, verbose)
    def self.fsck_NxNode(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_NxNode(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "NxNode" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
        FileSystemCheck::ensureAttribute(item, "description", "String")
    end

    # -----------------------------------------------------

    # FileSystemCheck::fsck_MikuTypedItem(item, verbose)
    def self.fsck_MikuTypedItem(item, verbose)

        if verbose then
            puts "FileSystemCheck::fsck_MikuTypedItem(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        mikuType = item["mikuType"]

        if mikuType == "NxWTimeCommitment" then
            FileSystemCheck::fsck_NxWTimeCommitment(item, verbose)
            return
        end

        if mikuType == "Dx33" then
            FileSystemCheck::fsck_Dx33(item, verbose)
            return
        end

        if mikuType == "NxAnniversary" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "startdate", "String")
            FileSystemCheck::ensureAttribute(item, "repeatType", "String")
            FileSystemCheck::ensureAttribute(item, "lastCelebrationDate", "String")
            return
        end

        if mikuType == "NxBall" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "accounts", "Array")
            FileSystemCheck::ensureAttribute(item, "itemuuid", "String")
            return
        end

        if mikuType == "NxDoNotShowUntil" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if mikuType == "NxNetworkLocalView" then
            FileSystemCheck::ensureAttribute(item, "center", "String")
            FileSystemCheck::ensureAttribute(item, "parents", "Array")
            FileSystemCheck::ensureAttribute(item, "related", "Array")
            FileSystemCheck::ensureAttribute(item, "children", "Array")
            return
        end

        if mikuType == "NxTodo" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "tcId", "String")
            FileSystemCheck::ensureAttribute(item, "tcPos", "Number")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "NxTriage" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "NxOndate" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            return
        end

        if mikuType == "NxNode" then
            FileSystemCheck::fsck_NxNode(item, verbose)
            return
        end

        if mikuType == "TxManualCountDown" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "dailyTarget", "Number")
            FileSystemCheck::ensureAttribute(item, "date", "String")
            FileSystemCheck::ensureAttribute(item, "counter", "Number")
            return
        end

        if mikuType == "TxFloat" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            return
        end

        if mikuType == "Wave" then
            FileSystemCheck::ensureAttribute(item, "uuid", "String")
            FileSystemCheck::ensureAttribute(item, "mikuType", "String")
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx46", "Hash")
            FileSystemCheck::ensureAttribute(item, "priority", "String")
            FileSystemCheck::ensureAttribute(item, "lastDoneDateTime", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], verbose)
            if item["nx23"] then
                raise "Waves should not carry a Nx23"
            end
            return
        end

        raise "Unsupported Miku Type '#{mikuType}' in #{JSON.pretty_generate(item)}"
    end

    # -----------------------------------------------------

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckErrorAtFirstFailure()
    def self.fsckErrorAtFirstFailure()
        [
            Anniversaries::items(),
            NxWTimeCommitments::items(),
            NxOndates::items(),
            NxTodosIO::items(),
            NxTriages::items(),
            TxFloats::items(),
            TxManualCountDowns::items(),
            Waves::items()
        ]
            .flatten
            .each{|item|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsck_MikuTypedItem(item, true)
            }
        puts "fsck completed successfully".green
    end
end
