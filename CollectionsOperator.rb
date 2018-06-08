
# encoding: UTF-8


# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# CollectionsOperator::collectionsFolderpaths()
# CollectionsOperator::folderPath2CollectionUUIDOrNull(folderpath)
# CollectionsOperator::folderPath2CollectionName(folderpath)
# CollectionsOperator::folderPath2CollectionObject(folderpath)
# CollectionsOperator::collectionUUID2FolderpathOrNull(uuid)
# CollectionsOperator::collectionsUUIDs()
# CollectionsOperator::collectionsNames()
# CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)

# CollectionsOperator::textContents(collectionuuid)
# CollectionsOperator::documentsFilenames(collectionuuid)

# CollectionsOperator::createNewCollection_WithNameAndStyle(collectionname, style)

# CollectionsOperator::addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
# CollectionsOperator::addObjectUUIDToCollectionInteractivelyChosen(objectuuid, threaduuid)
# CollectionsOperator::collectionCatalystObjectUUIDs(threaduuid)
# CollectionsOperator::collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
# CollectionsOperator::allCollectionsCatalystUUIDs()

# CollectionsOperator::setCollectionStyle(collectionuuid, style)
# CollectionsOperator::getCollectionStyle(collectionuuid)

# CollectionsOperator::isGuardianTime?(collectionuuid)

# CollectionsOperator::transform()
# CollectionsOperator::sendCollectionToBinTimeline(uuid)
# CollectionsOperator::getCollectionTimeCoefficient(uuid)
# CollectionsOperator::agentDailyCommitmentInHours()
# CollectionsOperator::getCollectionTimeCoefficient(uuid)

# CollectionsOperator::interactivelySelectCollectionUUIDOrNUll()
# CollectionsOperator::ui_CollectionsDive()
# CollectionsOperator::ui_CollectionDive(collectionuuid)

class CollectionsOperator

    # ---------------------------------------------------
    # Utils

    def self.collectionsFolderpaths()
        Dir.entries(CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH)
            .select{|filename| filename[0,1]!="." }
            .sort
            .map{|filename| "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{filename}" }
    end

    def self.collectionsUUIDs()
        CollectionsOperator::collectionsFolderpaths().map{|folderpath| CollectionsOperator::folderPath2CollectionUUIDOrNull(folderpath) }
    end

    def self.collectionsNames()
        CollectionsOperator::collectionsFolderpaths().map{|folderpath| CollectionsOperator::folderPath2CollectionName(folderpath) }
    end

    def self.folderPath2CollectionUUIDOrNull(folderpath)
        IO.read("#{folderpath}/collection-uuid")
    end

    def self.folderPath2CollectionName(folderpath)
        IO.read("#{folderpath}/collection-name")
    end

    def self.collectionUUID2FolderpathOrNull(uuid)
        CollectionsOperator::collectionsFolderpaths()
            .each{|folderpath|
                return folderpath if CollectionsOperator::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.collectionUUID2NameOrNull(uuid)
        CollectionsOperator::collectionsFolderpaths()
            .each{|folderpath|
                return IO.read("#{folderpath}/collection-name").strip if CollectionsOperator::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    # ---------------------------------------------------
    # text and documents

    def self.textContents(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return "" if folderpath.nil?
        IO.read("#{folderpath}/collection-text.txt")
    end    

    def self.documentsFilenames(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return [] if folderpath.nil?
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }
    end

    # ---------------------------------------------------
    # creation

    def self.createNewCollection_WithNameAndStyle(collectionname, style)
        collectionuuid = SecureRandom.hex(4)
        foldername = LucilleCore::timeStringL22()
        folderpath = "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{foldername}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/collection-uuid", "w"){|f| f.write(collectionuuid) }
        File.open("#{folderpath}/collection-name", "w"){|f| f.write(collectionname) }
        File.open("#{folderpath}/collection-catalyst-uuids.json", "w"){|f| f.puts(JSON.generate([])) }
        FileUtils.touch("#{folderpath}/collection-text.txt")
        FileUtils.mkpath "#{folderpath}/documents"
        self.setCollectionStyle(collectionuuid, style)
        collectionuuid
    end

    # ---------------------------------------------------
    # collections uuids

    def self.addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(threaduuid)
        arrayFilepath = "#{folderpath}/collection-catalyst-uuids.json"
        array = JSON.parse(IO.read(arrayFilepath))
        array << objectuuid 
        array = array.uniq
        File.open(arrayFilepath, "w"){|f| f.puts(JSON.generate(array)) }
    end

    def self.addObjectUUIDToCollectionInteractivelyChosen(objectuuid)
        collectionuuid = CollectionsOperator::interactivelySelectCollectionUUIDOrNUll()
        if collectionuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new collection ? ") then
                collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
                style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
                collectionuuid = CollectionsOperator::createNewCollection_WithNameAndStyle(collectionname, style)
            else
                return
            end
        end
        CollectionsOperator::addCatalystObjectUUIDToCollection(objectuuid, collectionuuid)
        collectionuuid
    end

    def self.collectionCatalystObjectUUIDs(collectionuuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json"))
    end

    def self.collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
        a1 = CollectionsOperator::collectionCatalystObjectUUIDs(collectionuuid)
        a2 = FlockOperator::flockObjects().map{|object| object["uuid"] }
        a1 & a2
    end

    def self.allCollectionsCatalystUUIDs()
        CollectionsOperator::collectionsFolderpaths()
            .map{|folderpath| JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json")) }
            .flatten
    end

    # ---------------------------------------------------
    # style

    def self.setCollectionStyle(collectionuuid, style)
        if !["THREAD", "PROJECT"].include?(style) then
            raise "Incorrect Style: #{style}, should be THREAD or PROJECT"
        end
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        File.open(filepath, "w"){|f| f.write(style) }
    end

    def self.getCollectionStyle(collectionuuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        IO.read(filepath).strip        
    end

    # ---------------------------------------------------
    # isGuardianTime?(collectionuuid)

    def self.isGuardianTime?(collectionuuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/isGuardianTime?"
        if !File.exists?(filepath) then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("#{CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)} is Guardian time? ") then
                File.open(filepath, "w"){|f| f.write("true") }
            else
                File.open(filepath, "w"){|f| f.write("false") }
            end
        end
        IO.read(filepath).strip == "true" 
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = self.allCollectionsCatalystUUIDs()
        FlockOperator::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
                FlockOperator::addOrUpdateObject(object)
            end
        }
    end

    def self.sendCollectionToBinTimeline(uuid)
        sourcefilepath = CollectionsOperator::collectionUUID2FolderpathOrNull(uuid)
        return if sourcefilepath.nil?
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        puts "source: #{sourcefilepath}"
        puts "target: #{targetFolder}"
        LucilleCore::copyFileSystemLocation(sourcefilepath, targetFolder)
        LucilleCore::removeFileSystemLocation(sourcefilepath)
    end

    def self.getCollectionTimeCoefficient(uuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(uuid)
        if folderpath.nil? then
            raise "error e95e2fda: Could not find fodler path for uuid: #{uuid}" 
        end
        if File.exists?("#{folderpath}/collection-time-positional-coefficient") then
            return IO.read("#{folderpath}/collection-time-positional-coefficient").to_f
        end
        0
    end

    def self.getNextReviewUnixtime(collectionuuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        return 0 if !File.exists?(filepath)
        IO.read(filepath).to_i       
    end

    def self.setNextReviewUnixtime(collectionuuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        unixtime = Time.new.to_i + 86400*(1+rand) 
        File.open(filepath, "w"){|f| f.write(unixtime) }
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_CollectionDive(collectionuuid)
        loop {
            style = CollectionsOperator::getCollectionStyle(collectionuuid)
            textContents = CollectionsOperator::textContents(collectionuuid)
            documentsFilenames = CollectionsOperator::documentsFilenames(collectionuuid)
            catalystobjects = CollectionsOperator::collectionCatalystObjectUUIDs(collectionuuid)
                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem1 = "file      : (#{textContents.strip.size} characters)"
            menuItem2 = "documents : (#{documentsFilenames.size} files)"
            menuItem3 = "operation : recast as thread"
            menuItem4 = "operation : recast as project"
            menuItem5 = "operation : destroy"
            menuStringsOrCatalystObjects = catalystobjects + [menuItem1, menuItem2 ]
            if style == "PROJECT" then
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem3 ]
            end
            if style == "THREAD" then
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem4 ]
            end
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [menuItem5 ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    "object    : #{CommonsUtils::object2Line_v0(object)}"
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == menuItem1 then
                folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/collection-text.txt'")
                next
            end
            if menuChoice == menuItem2 then
                folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/documents'")
                next
            end
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this #{style.downcase} ? ") and LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Seriously ? ") then
                    if catalystobjects.size>0 then
                        puts "You now need to destroy all the objects"
                        LucilleCore::pressEnterToContinue()
                        loop {
                            catalystobjects = CollectionsOperator::collectionCatalystObjectUUIDs(collectionuuid)
                                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                                .compact
                                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                                .reverse
                            break if catalystobjects.size==0
                            object = catalystobjects.first
                            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                        }
                    end
                    puts "Moving collection folder to bin timeline"
                    collectionfolderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(collectionuuid)
                    targetFolder = CommonsUtils::newBinArchivesFolderpath()
                    FileUtils.mv(collectionfolderpath, targetFolder)
                end
                return
            end
            if menuChoice == menuItem4 then
                CollectionsOperator::setCollectionStyle(collectionuuid, "PROJECT")
                return
            end
            if menuChoice == menuItem3 then
                CollectionsOperator::setCollectionStyle(collectionuuid, "THREAD")
                return
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.ui_CollectionsDive()
        loop {
            toString = lambda{ |collectionuuid| 
                "#{CollectionsOperator::getCollectionStyle(collectionuuid).ljust(8)} : #{CollectionsOperator::collectionUUID2NameOrNull(collectionuuid)}"
            }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("threads", CollectionsOperator::collectionsUUIDs(), toString)
            break if collectionuuid.nil?
            CollectionsOperator::ui_CollectionDive(collectionuuid)
        }
    end

    def self.interactivelySelectCollectionUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collection", CollectionsOperator::collectionsUUIDs(), lambda{ |collectionuuid| CollectionsOperator::collectionUUID2NameOrNull(collectionuuid) })
    end

end