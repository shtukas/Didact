
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Ymir2Estate.rb"
=begin
    Ymir2Estate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
    Ymir2Estate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    Ymir2Estate::ymirLocationEnumerator(pathToYmir)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/AtlasCore.rb"

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# --------------------------------------------------------------------

class NyxEstate

    # NyxEstate::pathToYmir()
    def self.pathToYmir()
        "/Users/pascal/Galaxy/Nyx"
    end
end

class NyxCuration

    # NyxCuration::curate()
    def self.curate()

        # ----------------------------------------------------------------------------------------
        # Remove permanodes with no targets
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .select{|permanode| permanode["targets"].size == 0 }
            .each{|permanode|
                puts "Destroying permanode '#{permanode["description"]}' (no targets)"
                NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
            }

        # ----------------------------------------------------------------------------------------
        # Correct permanodes with descriptions with have more than one lines
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .select{|permanode|
                permanode["description"].lines.to_a.size > 1
            }
            .each{|permanode|
                puts "Correcting permanode description"
                permanode["description"] = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            }

    end
end

class NyxMiscUtils

    # NyxMiscUtils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # NyxMiscUtils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NyxMiscUtils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # NyxMiscUtils::cleanStringToBeFileSystemName(str)
    def self.cleanStringToBeFileSystemName(str)
        str = str.gsub(" ", "-")
        str = str.gsub("'", "-")
        str = str.gsub(":", "-")
        str = str.gsub("/", "-")
        str = str.gsub("!", "-")
        str
    end

    # NyxMiscUtils::locationsNamesInsideFolder(folderpath): Array[String]
    def self.locationsNamesInsideFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", ".."].include?(filename) }
            .reject{|filename| filename == "Icon\r" }
            .reject{|filename| filename == ".DS_Store" }
            .sort
    end

    # NyxMiscUtils::locationPathsInsideFolder(folderpath): Array[String]
    def self.locationPathsInsideFolder(folderpath)
        NyxMiscUtils::locationsNamesInsideFolder(folderpath).map{|filename| "#{folderpath}/#{filename}" }
    end

    # NyxMiscUtils::readFileAsIndividualNonEmptyStrippedLineItems(filepath)
    def self.readFileAsIndividualNonEmptyStrippedLineItems(filepath)
        IO.read(filepath).lines.map{|line| line.strip }.select{|line| line.size > 0 }
    end

    # NyxMiscUtils::recursivelyComputedLocationTrace(location): String
    def self.recursivelyComputedLocationTrace(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{location}:#{File.mtime(location)}")
        else
            Digest::SHA1.hexdigest(
                ([location] + NyxMiscUtils::locationPathsInsideFolder(location).map{|l| NyxMiscUtils::recursivelyComputedLocationTrace(l) }).join("::")
            )
        end
    end

    # NyxMiscUtils::rsync(sourceFolderpath, targetFolderpath)
    def self.rsync(sourceFolderpath, targetFolderpath)
        if !File.exists?(sourceFolderpath) then
            raise "[error: 653b1b57] Impossible rsync" 
        end
        command = "rsync --xattrs --times --recursive --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes --links '#{sourceFolderpath}/' '#{targetFolderpath}'"
        system(command)
    end

    # NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(mark)
    def self.lStoreMarkResolutionToMarkFilepathOrNull(mark)
        location = AtlasCore::uniqueStringToLocationOrNull(mark)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::isProperDateTimeIso8601(datetime)
    def self.isProperDateTimeIso8601(datetime)
        DateTime.parse(datetime).to_time.utc.iso8601 == datetime
    end

    # NyxMiscUtils::formatTimeline(timeline)
    def self.formatTimeline(timeline)
        timeline.split(" ").map{|word| word.downcase.capitalize }.join(" ")
    end

    # NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("location", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()
    def self.selectOneOrMoreFilesOnTheDesktopByLocation() # Array[String]
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1]!='.' }
                            .sort
        puts "Select files:"
        locations, _ = LucilleCore::selectZeroOrMore("files:", [], desktopLocations, lambda{ |location| File.basename(location) })
        locations
    end

    # NyxMiscUtils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # NyxMiscUtils::nyxStringDistance(str1, str2)
    def self.nyxStringDistance(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        NyxMiscUtils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end
end

class NyxPermanodeOperator

    # ------------------------------------------
    # Integrity

    # NyxPermanodeOperator::objectIsPermanodeTarget(object)
    def self.objectIsPermanodeTarget(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["type"].nil?
        types = [
            "url-EFB8D55B",
            "file-3C93365A",
            "unique-name-C2BF46D6",
            "lstore-directory-mark-BEE670D0",
            "perma-dir-11859659"
        ]
        return false if !types.include?(object["type"])
        if object["type"] == "perma-dir-11859659" then
            return false if object["foldername"].nil?
            return false if !File.exists?("/Users/pascal/Galaxy/Nyx-Permadirs/#{object["foldername"]}")
        end
        true
    end

    # Return true if the passed object is a well formed permanode
    # NyxPermanodeOperator::objectIsPermanode(object)
    def self.objectIsPermanode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["referenceDateTime"].nil?
        return false if DateTime.parse(object["referenceDateTime"]).to_time.utc.iso8601 != object["referenceDateTime"]
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["targets"].nil?
        return false if object["targets"].any?{|target| !NyxPermanodeOperator::objectIsPermanodeTarget(target) }
        return false if object["tags"].nil?
        return false if object["streams"].nil?
        true
    end

    # ------------------------------------------------------------------
    # To Strings

    # NyxPermanodeOperator::permanodeTargetToString(target)
    def self.permanodeTargetToString(target)
        if target["type"] == "url-EFB8D55B" then
            return "url       : #{target["url"]}"
        end
        if target["type"] == "file-3C93365A" then
            return "file      : #{target["filename"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "uniquename: #{target["name"]}"
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return "mark      : #{target["mark"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            return "PermaDir  : #{target["uuid"]}"
        end
        raise "[error: f84bb73d]"
    end

    # NyxPermanodeOperator::printPermanodeDetails(permanode)
    def self.printPermanodeDetails(permanode)
        puts "Permanode:"
        puts "    uuid: #{permanode["uuid"]}"
        puts "    filename: #{permanode["filename"]}"
        puts "    description: #{permanode["description"].green}"
        puts "    datetime: #{permanode["referenceDateTime"]}"
        puts "    targets:"
        permanode["targets"].each{|permanodeTarget|
            puts "        #{NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)}"
        }
        if permanode["tags"].empty? then
            puts "    tags: (empty set)".green
        else
            puts "    tags"
            permanode["tags"].each{|item|
                puts "        #{item}".green
            }
        end
        if permanode["streams"].empty? then
            puts "    streams: (empty set)".green
        else
            puts "    streams"
            permanode["streams"].each{|item|
                puts "        #{item}".green
            }
        end
    end

    # ------------------------------------------
    # Opening

    # NyxPermanodeOperator::fileCanBeSafelyOpen(filename)
    def self.fileCanBeSafelyOpen(filename)
        true # TODO
    end

    # NyxPermanodeOperator::openPermanodeTarget(pathToYmir, target)
    def self.openPermanodeTarget(pathToYmir, target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            system("open '#{url}'")
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            filepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(pathToYmir, filename)
            if NyxPermanodeOperator::fileCanBeSafelyOpen(filename) then
                system("open '#{filepath}'")
            else
                puts "Copying file to Desktop: #{File.basename(filepath)}"
                File.cp(filepath, "/Users/pascal/Desktop/#{File.basename(filepath)}")
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location then
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{target["mark"]}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = "/Users/pascal/Galaxy/Nyx-Permadirs/#{target["foldername"]}"
            if !File.exists?(folderpath) then
                puts "[error: dbd35b00] This should not have happened. Cannot find folder for permadir foldername '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxPermanodeOperator::permanodeOptimisticOpen(permanode)
    def self.permanodeOptimisticOpen(permanode)
        NyxPermanodeOperator::printPermanodeDetails(permanode)
        puts "    -> Opening..."
        if permanode["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this permanode. Dive? ") then
                NyxUserInterface::permanodeDive(permanode)
            end
            return
        end
        target = nil
        if permanode["targets"].size == 1 then
            target = permanode["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", permanode["targets"], lambda{|target| NyxPermanodeOperator::permanodeTargetToString(target) })
        end
        puts JSON.pretty_generate(target)
        NyxPermanodeOperator::openPermanodeTarget(NyxEstate::pathToYmir(), target)
    end

    # ------------------------------------------
    # IO Ops

    # NyxPermanodeOperator::makePermanodeFilename()
    def self.makePermanodeFilename()
        "#{NyxMiscUtils::l22()}.json"
    end

    # NyxPermanodeOperator::destroyPermanode(pathToYmir, permanode)
    def self.destroyPermanode(pathToYmir, permanode)
        filepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(pathToYmir, permanode["filename"])
        puts filepath
        return if filepath.nil?
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NyxPermanodeOperator::commitNewPermanodeToDisk(pathToYmir, permanode)
    def self.commitNewPermanodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !NyxPermanodeOperator::objectIsPermanode(permanode)
        filepath = Ymir2Estate::makeNewYmirLocationForBasename(pathToYmir, permanode["filename"])
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # NyxPermanodeOperator::recommitPermanodeToDisk(pathToYmir, permanode)
    def self.recommitPermanodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !NyxPermanodeOperator::objectIsPermanode(permanode)
        filepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(pathToYmir, permanode["filename"])
        if filepath.nil? then
            raise "[error: f1f2252d]"
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # NyxPermanodeOperator::getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
    def self.getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
        NyxPermanodeOperator::permanodesEnumerator(pathToYmir).each{|permanode|
            return permanode if ( permanode["uuid"] == permanodeuuid )
        }
        nil
    end

    # NyxPermanodeOperator::permanodesEnumerator(pathToYmir)
    def self.permanodesEnumerator(pathToYmir)
        isFilenameOfPermanode = lambda {|filename|
            filename[-5, 5] == ".json"
        }
        Enumerator.new do |permanodes|
            Ymir2Estate::ymirLocationEnumerator(pathToYmir).each{|location|
                next if !isFilenameOfPermanode.call(File.basename(location))
                filepath = location
                permanode = JSON.parse(IO.read(filepath))
                permanodes << permanode
            }
        end
    end

    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxPermanodeOperator::selectPermanodeOrNull(permanodes)
    def self.selectPermanodeOrNull(permanodes)
        descriptionXp = lambda { |permanode|
            "#{permanode["description"]} (#{permanode["uuid"][0,4]})"
        }
        descriptionsxp = permanodes.map{|permanode| descriptionXp.call(permanode) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select permanode (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        permanode = permanodes.select{|permanode| descriptionXp.call(permanode) == selectedDescriptionxp }.first
        return nil if permanode.nil?
        permanode
    end

    # NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(mark)
    def self.getPermanodesCarryingThisDirectoryMark(mark)
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .select{|permanode|
                permanode["targets"].any?{|target| target["type"] == "lstore-directory-mark-BEE670D0" and target["mark"] == mark }
            }
    end

    # NyxPermanodeOperator::tags()
    def self.tags()
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .map{|permanode| permanode["tags"]}
            .flatten
            .uniq
            .sort
    end

    # NyxPermanodeOperator::streams()
    def self.streams()
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .map{|permanode| permanode["streams"] }
            .flatten
            .uniq
            .sort
    end

    # NyxPermanodeOperator::permanodeBelongsToTag(permanode, tag)
    def self.permanodeBelongsToTag(permanode, tag)
        permanode["tags"].map{|t| t.downcase }.include?(tag.downcase)
    end

    # ------------------------------------------------------------------
    # Interactive Makers

    # NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
    def self.makePermanodeTargetFileInteractiveOrNull()
        filepath1 = NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{NyxMiscUtils::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        filepath3 = Ymir2Estate::makeNewYmirLocationForBasename(NyxEstate::pathToYmir(), filename2)
        FileUtils.mv(filepath2, filepath3)
        return {
            "uuid"     => SecureRandom.uuid,
            "type"     => "file-3C93365A",
            "filename" => filename2
        }
    end

    # NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
    def self.makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                targetFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the target folder: ")
                if !File.exists?(targetFolderLocation) then
                    puts "I can't see location '#{targetFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{targetFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
    end

    # NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(type)
    # type = nil | "url-EFB8D55B" | "file-3C93365A" | "unique-name-C2BF46D6" | "lstore-directory-mark-BEE670D0" | "perma-dir-11859659"
    def self.makePermanodeTargetInteractiveOrNull(type)
        permanodeTargetType =
            if type.nil? then
                LucilleCore::selectEntityFromListOfEntitiesOrNull("type", [
                    "url-EFB8D55B",
                    "unique-name-C2BF46D6",
                    "file-3C93365A",
                    "lstore-directory-mark-BEE670D0",
                    "perma-dir-11859659"]
                )
            else
                type
            end
        return nil if permanodeTargetType.nil?
        if permanodeTargetType == "url-EFB8D55B" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ").strip
            }
        end
        if permanodeTargetType == "file-3C93365A" then
            return NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
        end
        if permanodeTargetType == "unique-name-C2BF46D6" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("uniquename: ").strip
            }
        end
        if permanodeTargetType == "lstore-directory-mark-BEE670D0" then
            return NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        end
        if permanodeTargetType == "perma-dir-11859659" then
            desktopLocationnames = Dir.entries("/Users/pascal/Desktop")
                                    .reject{|filename| filename[0, 1] == '.' }
                                    .reject{|filename| ["pascal.png", "Lucille-Inbox", "Lucille.txt"].include?(filename) }
            selecteddesktopLocationnames, _ = LucilleCore::selectZeroOrMore("file", [], desktopLocationnames)
            return nil if selecteddesktopLocationnames.empty?
            foldername2 = NyxMiscUtils::l22()
            folderpath2 = "/Users/pascal/Galaxy/Nyx-Permadirs/#{foldername2}"
            FileUtils.mkdir(folderpath2)
            selecteddesktopLocations = selecteddesktopLocationnames.map{|filename| "/Users/pascal/Desktop/#{filename}" }
            selecteddesktopLocations.each{|desktoplocation|
                puts "Migrating '#{desktoplocation}' to '#{folderpath2}'"
                LucilleCore::copyFileSystemLocation(desktoplocation, folderpath2)
                LucilleCore::removeFileSystemLocation(desktoplocation)
            }
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        nil
    end

    # NyxPermanodeOperator::makeOnePermanodeTagInteractiveOrNull()
    def self.makeOnePermanodeTagInteractiveOrNull()
        inputToTextDisplay = lambda { |input|
            return "" if input.size < 3
            NyxSearch::searchPatternToTags(input).join("\n")
        }
        fragment = CatalystCommon::interactiveVisualisation(inputToTextDisplay)
        return nil if fragment == ";"
        if fragment[-1, 1] == ";" then
            fragment = fragment[0, fragment.size-1]
        end
        return nil if fragment.size == 0
        fragment
    end

    # NyxPermanodeOperator::makePermanodeTagsInteractive()
    def self.makePermanodeTagsInteractive()
        tags = []
        loop {
            puts "Making tag"
            LucilleCore::pressEnterToContinue()
            tag = NyxPermanodeOperator::makeOnePermanodeTagInteractiveOrNull()
            break if tag.nil?
            tags << tag
        }
        tags
    end

    # NyxPermanodeOperator::makeOnePermanodeStreamInteractiveOrNull()
    def self.makeOnePermanodeStreamInteractiveOrNull()
        inputToTextDisplay = lambda { |input|
            return "" if input.size < 3
            NyxSearch::searchPatternToStreams(input).join("\n")
        }
        fragment = CatalystCommon::interactiveVisualisation(inputToTextDisplay)
        return nil if fragment == ";"
        if fragment[-1, 1] == ";" then
            fragment = fragment[0, fragment.size-1]
        end
        return nil if fragment.size == 0
        fragment
    end

    # NyxPermanodeOperator::makePermanodeStreamsInteractive()
    def self.makePermanodeStreamsInteractive()
        streams = []
        loop {
            stream = NyxPermanodeOperator::makeOnePermanodeStreamInteractiveOrNull()
            break if stream.nil?
            streams << stream
        }
        streams
    end

    # NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
    def self.makePermanode2Interactive(description, permanodeTarget)
        permanode = {}
        permanode["uuid"] = SecureRandom.uuid
        permanode["filename"] = NyxPermanodeOperator::makePermanodeFilename()
        permanode["creationTimestamp"] = Time.new.to_f
        permanode["referenceDateTime"] = Time.now.utc.iso8601
        permanode["description"] = description
        permanode["targets"] = [ permanodeTarget ]
        permanode["tags"] = NyxPermanodeOperator::makePermanodeTagsInteractive()
        permanode["streams"] = NyxPermanodeOperator::makePermanodeStreamsInteractive()
        permanode
    end

    # NyxPermanodeOperator::makePermanode1Interactive()
    def self.makePermanode1Interactive()
        operations = [
            "url",
            "uniquename",
            "file (from desktop)",
            "lstore-directory-mark",
            "Desktop files inside permadir"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)

        if operation == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url" => url
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxPermanodeOperator::commitNewPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
        end

        if operation == "uniquename" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => uniquename
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxPermanodeOperator::commitNewPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
        end

        if operation == "file (from desktop)" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            permanodeTarget = NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
            return if permanodeTarget.nil?
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxPermanodeOperator::commitNewPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
        end

        if operation == "lstore-directory-mark" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            permanodeTarget = NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
            return if permanodeTarget.nil?
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxPermanodeOperator::commitNewPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
        end

        if operation == "Desktop files inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            locations = NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()

            foldername2 = NyxMiscUtils::l22()
            f2olderpath2 = "/Users/pascal/Galaxy/Nyx-Permadirs/#{foldername2}"
            FileUtils.mkdir(folderpath2)

            permanodeTarget = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxPermanodeOperator::commitNewPermanodeToDisk(NyxEstate::pathToYmir(), permanode)

            locations.each{|location|
                puts "Copying '#{location}'"
                LucilleCore::copyFileSystemLocation(location, folderpath2)
            }
            locations.each{|location|
                LucilleCore::removeFileSystemLocation(location)
            }
            system("open '#{folderpath2}'")
        end
    end

    # ------------------------------------------------------------------
    # Destroy

    # NyxPermanodeOperator::destroyPermanodeTargetAttempt(target)
    def self.destroyPermanodeTargetAttempt(target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            filepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(NyxEstate::pathToYmir(), filename)
            if File.exists?(filepath) then
                FileUtils.rm(filepath)
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            return if location.nil?
            if NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(target["mark"]).size == 1 then
                puts "destroying mark file: #{location}"
                LucilleCore::removeFileSystemLocation(location)
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = "/Users/pascal/Galaxy/Nyx-Permadirs/#{target["foldername"]}"
            return if folderpath.nil?
            LucilleCore::removeFileSystemLocation(folderpath)
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
    def self.destroyPermanodeAttempt(permanode)
        permanode["targets"].all?{|target| NyxPermanodeOperator::destroyPermanodeTargetAttempt(target) }
        NyxPermanodeOperator::destroyPermanode(NyxEstate::pathToYmir(), permanode)
    end

    # NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
    def self.destroyPermanodeContentsAndPermanode(permanodeuuid)
        permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), permanodeuuid)
        return if permanode.nil?
        NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
    end
end

class NyxSearch

    # NyxSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        NyxPermanodeOperator::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end
    # NyxSearch::searchPatternToStreams(searchPattern)
    def self.searchPatternToStreams(searchPattern)
        NyxPermanodeOperator::streams()
            .select{|stream| stream.downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToPermanodes(searchPattern)
    def self.searchPatternToPermanodes(searchPattern)
        NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
            .select{|permanode| permanode["description"].downcase.include?(searchPattern.downcase) }
    end

    # NyxSearch::searchPatternToPermanodeDescriptions(searchPattern)
    def self.searchPatternToPermanodeDescriptions(searchPattern)
        NyxSearch::searchPatternToPermanodes(searchPattern)
            .map{|permanode| permanode["description"] }
            .uniq
            .sort
    end

    # NyxSearch::nextGenGetSearchFragmentOrNull()
    def self.nextGenGetSearchFragmentOrNull() # () -> String
        inputToTextDisplay = lambda { |input|
            return "" if input.size < 3 
            str1 = NyxSearch::searchPatternToPermanodeDescriptions(input)
                    .map{|description| "permanode: #{description}" }
                    .join("\n")
            str2 = NyxSearch::searchPatternToTags(input)
                    .map{|tag| "tag: #{tag}" }
                    .join("\n")
            str3 = NyxSearch::searchPatternToStreams(input)
                    .map{|stream| "stream #{stream}" }
                    .join("\n")
            [ str1, str2, str3 ].join("\n\n")
        }
        fragment = CatalystCommon::interactiveVisualisation(inputToTextDisplay)
        return nil if fragment == ";"
        if fragment[-1, 1] == ";" then
            fragment = fragment[0, fragment.size-1]
        end
        return nil if fragment.size == 0
        fragment
    end

    # NyxSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = NyxSearch::searchPatternToPermanodes(fragment)
                    .map{|permanode| 
                        {
                            "type" => "permanode",
                            "permanode" => permanode
                        }
                    }
        objs2 = NyxSearch::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # NyxSearch::globalSearchStructureDive(globalss)
    def self.globalSearchStructureDive(globalss)
        loop {
            system("clear")
            globalssObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "permanode" then
                    permanode = object["permanode"]
                    return [ "permanode: #{permanode["description"]}" , lambda { NyxUserInterface::permanodeDive(permanode) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { NyxUserInterface::nextGenTagDive(tag) } ]
                end
                nil
            }
            items = globalss
                .map{|object| globalssObjectToMenuItemOrNull.call(object) }
                .compact
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # NyxSearch::search()
    def self.search()
        fragment = NyxSearch::nextGenGetSearchFragmentOrNull()
        return if fragment.nil?
        globalss = NyxSearch::nextGenSearchFragmentToGlobalSearchStructure(fragment)
        NyxSearch::globalSearchStructureDive(globalss)
    end
end

class NyxUserInterface

    # NyxUserInterface::permanodeTargetDive(permanodeuuid, permanodeTarget)
    def self.permanodeTargetDive(permanodeuuid, permanodeTarget)
        puts "-> permanodeTarget:"
        puts JSON.pretty_generate(permanodeTarget)
        puts NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)
        NyxPermanodeOperator::openPermanodeTarget(NyxEstate::pathToYmir(), permanodeTarget)
    end

    # NyxUserInterface::permanodeTargetsDive(permanode)
    def self.permanodeTargetsDive(permanode)
        toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
        permanodeTarget = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", permanode["targets"], toStringLambda)
        return if permanodeTarget.nil?
        NyxUserInterface::permanodeTargetDive(permanode["uuid"], permanodeTarget)
    end

    # NyxUserInterface::permanodeDive(permanode)
    def self.permanodeDive(permanode)
        loop {
            NyxPermanodeOperator::printPermanodeDetails(permanode)
            operations = [
                "quick open",
                "edit description",
                "edit reference datetime",
                "targets dive",
                "targets (add new)",
                "targets (select and remove)",
                "tags (add new)",
                "tags (remove)",
                "streams (add new)",
                "streams (remove)",
                "edit permanode.json",
                "destroy permanode"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                NyxPermanodeOperator::permanodeOptimisticOpen(permanode)
            end
            if operation == "edit description" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), permanode["uuid"])
                newdescription = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                if newdescription == "" or newdescription.lines.to_a.size != 1 then
                    puts "Descriptions should have one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                permanode["description"] = newdescription
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "edit reference datetime" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), permanode["uuid"])
                referenceDateTime = NyxMiscUtils::editTextUsingTextmate(permanode["referenceDateTime"]).strip
                if NyxMiscUtils::isProperDateTimeIso8601(referenceDateTime) then
                    permanode["referenceDateTime"] = referenceDateTime
                    NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
                else
                    puts "I could not validate #{referenceDateTime} as a proper iso8601 datetime"
                    puts "Aborting operation"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if operation == "target dive" then
                NyxUserInterface::permanodeTargetDive(permanode["uuid"], permanode["targets"].first)
            end
            if operation == "targets dive" then
                NyxUserInterface::permanodeTargetsDive(permanode)
            end
            if operation == "targets (add new)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), permanode["uuid"])
                target = NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(nil)
                next if target.nil?
                permanode["targets"] << target
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "targets (select and remove)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), permanode["uuid"])
                toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", permanode["targets"], toStringLambda)
                next if target.nil?
                permanode["targets"] = permanode["targets"].reject{|t| t["uuid"]==target["uuid"] }
                NyxPermanodeOperator::destroyPermanodeTargetAttempt(target)
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "tags (add new)" then
                tag = NyxPermanodeOperator::makeOnePermanodeTagInteractiveOrNull()
                next if tag.nil?
                permanode["tags"] << tag
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "tags (remove)" then
                tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", permanode["tags"])
                next if tag.nil?
                permanode["tags"] = permanode["tags"].reject{|t| t == tag }
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "streams (add new)" then
                stream = NyxPermanodeOperator::makeOnePermanodeStreamInteractiveOrNull()
                next if stream.nil?
                permanode["streams"] << stream
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "streams (remove)" then
                stream = LucilleCore::selectEntityFromListOfEntitiesOrNull("stream", permanode["streams"])
                next if stream.nil?
                permanode["streams"] = permanode["streams"].reject{|x| x == stream }
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "edit permanode.json" then
                permanodeFilepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(NyxEstate::pathToYmir(), permanode["filename"])
                if permanodeFilepath.nil? then
                    puts "Strangely I could not find the filepath for this:"
                    puts JSON.pretty_generate(permanode)
                    LucilleCore::pressEnterToContinue()
                    next
                end
                puts "permanode filepath: #{permanodeFilepath}"
                permanodeAsJSONString = NyxMiscUtils::editTextUsingTextmate(JSON.pretty_generate(JSON.parse(IO.read(permanodeFilepath))))
                permanode = JSON.parse(permanodeAsJSONString)
                if !NyxPermanodeOperator::objectIsPermanode(permanode) then
                    puts "I do not recognise the new object as a permanode. Aborting operation."
                    next
                end
                NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
            end
            if operation == "destroy permanode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanode["uuid"])
                    return
                end
            end
        }
    end

    # NyxUserInterface::permanodesDive(permanodes)
    def self.permanodesDive(permanodes)
        loop {
            permanode = NyxPermanodeOperator::selectPermanodeOrNull(permanodes)
            break if permanode.nil?
            NyxUserInterface::permanodeDive(permanode)
        }
    end

    # NyxUserInterface::nextGenTagDive(tag)
    def self.nextGenTagDive(tag)
        loop {
            system('clear')
            puts "Tag diving: #{tag}"
            items = []
            NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
                .select{|permanode| NyxPermanodeOperator::permanodeBelongsToTag(permanode, tag) }
                .each{|permanode|
                    items << [ permanode["description"] , lambda { NyxUserInterface::permanodeDive(permanode) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # ------------------------------------------

    # NyxUserInterface::uimainloop()
    def self.uimainloop()
        loop {
            system("clear")
            puts "Nyx 🗺️"
            operations = [
                # Search
                "search",

                # View
                "show newly created permanodes",
                "permanode dive (uuid)",

                # Make or modify
                "make new permanode",
                "repair permanode (uuid)",

                # Special operations
                "rename tag",
                "rename stream",
                "curation",

                # Destroy
                "permanode destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                NyxSearch::search()
            end
            if operation == "rename tag" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameTagIfNeeded = lambda {|tag, oldname, newname|
                    if tag.downcase == oldname.downcase then
                        tag = newname
                    end
                    tag
                }
                NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
                    .each{|permanode|
                        h1 = permanode.to_s
                        permanode["tags"] = permanode["tags"].map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        h2 = permanode.to_s
                        if h1 != h2 then
                            puts JSON.pretty_generate(permanode)
                            NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
                        end
                    }
            end
            if operation == "rename stream" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameStreamIfNeeded = lambda {|stream, oldname, newname|
                    if stream.downcase == oldname.downcase then
                        stream = newname
                    end
                    stream
                }
                NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
                    .each{|permanode|
                        h1 = permanode.to_s
                        permanode["streams"] = permanode["streams"].map{|stream| renameStreamIfNeeded.call(stream, oldname, newname) }
                        h2 = permanode.to_s
                        if h1 != h2 then
                            puts JSON.pretty_generate(permanode)
                            NyxPermanodeOperator::recommitPermanodeToDisk(NyxEstate::pathToYmir(), permanode)
                        end
                    }
            end
            if operation == "permanode dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), uuid)
                if permanode then
                    NyxUserInterface::permanodeDive(permanode)
                else
                    puts "Could not find permanode for uuid (#{uuid})"
                end
            end
            if operation == "repair permanode (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(NyxEstate::pathToYmir(), uuid)
                next if permanode.nil?
                filepath = Ymir2Estate::locationBasenameToYmirLocationOrNull(NyxEstate::pathToYmir(), permanode["filename"])
                next if filepath.nil?
                system("open '#{filepath}'")
                LucilleCore::pressEnterToContinue()
            end

            if operation == "make new permanode" then
                NyxPermanodeOperator::makePermanode1Interactive()
            end
            if operation == "show newly created permanodes" then
                permanodes = NyxPermanodeOperator::permanodesEnumerator(NyxEstate::pathToYmir())
                                .sort{|p1, p2| p1["referenceDateTime"] <=> p2["referenceDateTime"] }
                                .reverse
                                .first(20)
                NyxUserInterface::permanodesDive(permanodes)
            end
            if operation == "curation" then
                NyxCuration::curate()
            end
            if operation == "permanode destroy (uuid)" then
                permanodeuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
                end
            end
        }
    end
end
