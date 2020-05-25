# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataEntities.rb"

# -----------------------------------------------------------------

class StartlightNodes

    # StartlightNodes::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/nodes"
    end

    # StartlightNodes::save(node)
    def self.save(node)
        filepath = "#{StartlightNodes::path()}/#{node["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(node)) }
    end

    # StartlightNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightNodes::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightNodes::nodes()
    # Nodes are given in increasing creation timestamp
    def self.nodes()
        Dir.entries(StartlightNodes::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightNodes::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightNodes::makeNodeInteractivelyOrNull(canAskToMakeAParent)
    def self.makeNodeInteractivelyOrNull(canAskToMakeAParent)
        puts "Making a new Starlight node..."
        node = {
            "catalystType"      => "catalyst-type:starlight-node",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
        StartlightNodes::save(node)
        puts JSON.pretty_generate(node)
        if canAskToMakeAParent and LucilleCore::askQuestionAnswerAsBoolean("Would you like to give a parent to this new node ? ") then
            xnode = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
            if xnode then
                StartlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(xnode, node)
            end
        end
        node
    end

    # StartlightNodes::nodeToString(node)
    def self.nodeToString(node)
        "[starlight node] #{node["name"]} (#{node["uuid"][0, 4]})"
    end

    # StartlightNodes::nodeManagement(node)
    def self.nodeManagement(node)
        loop {
            puts JSON.pretty_generate(node)
            operations = [
                "rename"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "rename" then
                node["description"] = CatalystCommon::editTextUsingTextmate(node["description"]).strip
                StartlightNodes::save(node)
            end
        }
    end

    # StartlightNodes::nodeDive(node)
    def self.nodeDive(node)
        loop {
            puts JSON.pretty_generate(node)
            puts StartlightNodes::nodeToString(node).green
            puts "Network:"

            puts "    Parents"
            StarlightNavigationAndBuilding::getStarlightNetworkParentNodes(node).each{|n|
                puts "        #{StartlightNodes::nodeToString(n)}"
            }

            puts "    Children"
            StarlightNavigationAndBuilding::getStarlightNetworkChildNodes(node).each{|n|
                puts "        #{StartlightNodes::nodeToString(n)}"
            }
            operations = [
                "node management"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "node management" then
                StartlightNodes::nodeManagement(node)
            end
        }
    end

    # StartlightNodes::nodesDive()
    def self.nodesDive()
        puts "StartlightNodes::nodesDive() not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

end

class StartlightPaths

    # StartlightPaths::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/paths"
    end

    # StartlightPaths::save(path)
    def self.save(path)
        filepath = "#{StartlightPaths::path()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # StartlightPaths::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightPaths::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightPaths::paths()
    def self.paths()
        Dir.entries(StartlightPaths::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightPaths::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightPaths::issuePathInteractivelyOrNull()
    def self.issuePathInteractivelyOrNull()
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "sourceuuid" => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid" => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
        StartlightPaths::save(path)
        path
    end

    # StartlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
    def self.issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
        return nil if node1["uuid"] == node2["uuid"]
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,
            "sourceuuid" => node1["uuid"],
            "targetuuid" => node2["uuid"]
        }
        StartlightPaths::save(path)
        path
    end

    # StartlightPaths::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        StartlightPaths::paths()
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # StartlightPaths::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        StartlightPaths::paths()
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # StartlightPaths::pathToString(path)
    def self.pathToString(path)
        "[starlight path] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end
end

class StarlightOwnershipClaims

    # StarlightOwnershipClaims::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/ownershipclaims"
    end

    # StarlightOwnershipClaims::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{StarlightOwnershipClaims::path()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # StarlightOwnershipClaims::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StarlightOwnershipClaims::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StarlightOwnershipClaims::claims()
    def self.claims()
        Dir.entries(StarlightOwnershipClaims::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StarlightOwnershipClaims::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StarlightOwnershipClaims::issueClaimGivenNodeAndDataPoint(node, datapoint)
    def self.issueClaimGivenNodeAndDataPoint(node, datapoint)
        claim = {
            "catalystType"      => "catalyst-type:starlight-node-ownership-claim",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "nodeuuid"   => node["uuid"],
            "targetuuid" => datapoint["uuid"]
        }
        StarlightOwnershipClaims::save(claim)
        claim
    end

    # StarlightOwnershipClaims::issueClaimGivenNodeAndCatalystStandardTarget(node, target)
    def self.issueClaimGivenNodeAndCatalystStandardTarget(node, target)
        claim = {
            "catalystType"      => "catalyst-type:starlight-node-ownership-claim",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "nodeuuid"   => node["uuid"],
            "targetuuid" => target["uuid"]
        }
        StarlightOwnershipClaims::save(claim)
        claim
    end

    # StarlightOwnershipClaims::claimToString(dataclaim)
    def self.claimToString(dataclaim)
        "[starlight ownership claim] #{dataclaim["nodeuuid"]} -> #{dataclaim["targetuuid"]}"
    end

    # StarlightOwnershipClaims::getDataEntitiesForNode(node)
    def self.getDataEntitiesForNode(node)
        StarlightOwnershipClaims::claims()
            .select{|claim| claim["nodeuuid"] == node["uuid"] }
            .map{|claim| DataEntities::getDataEntityByUuidOrNull(claim["targetuuid"]) }
            .compact
    end

    # StarlightOwnershipClaims::getNodesForDataPoint(datapoint)
    def self.getNodesForDataPoint(datapoint)
        StarlightOwnershipClaims::claims()
            .select{|claim| claim["targetuuid"] == datapoint["uuid"] }
            .map{|claim| StartlightNodes::getOrNull(claim["nodeuuid"]) }
            .compact
    end

end

class StarlightManagement
    # StarlightManagement::management()
    def self.management()
        loop {
            system("clear")
            puts "Starlight Management (root)"
            operations = [
                "make starlight node",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make starlight node" then
                node = StartlightNodes::makeNodeInteractivelyOrNull(true)
                puts JSON.pretty_generate(node)
                StartlightNodes::save(node)
            end
            if operation == "make starlight path" then
                node1 = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
                next if node1.nil?
                node2 = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
                next if node2.nil?
                path = StartlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
                puts JSON.pretty_generate(path)
                StartlightPaths::save(path)
            end
        }
    end
end

class StarlightNavigationAndBuilding

    # ----------------------------------------------
    # Navigation Utils

    # StarlightNavigationAndBuilding::getStarlightNetworkParentNodes(node)
    def self.getStarlightNetworkParentNodes(node)
        StartlightPaths::getPathsWithGivenTarget(node["uuid"])
            .map{|path| StartlightNodes::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # StarlightNavigationAndBuilding::getStarlightNetworkChildNodes(node)
    def self.getStarlightNetworkChildNodes(node)
        StartlightPaths::getPathsWithGivenSource(node["uuid"])
            .map{|path| StartlightNodes::getOrNull(path["targetuuid"]) }
            .compact
    end

    # StarlightNavigationAndBuilding::getRootNodes()
    def self.getRootNodes()
        StartlightNodes::nodes()
            .select{|node| StarlightNavigationAndBuilding::getStarlightNetworkParentNodes(node).empty? }
    end

    # ----------------------------------------------
    # Navigation User Interface

    # StarlightNavigationAndBuilding::nagivateNode(node)
    def self.nagivateNode(node)
        loop {
            system("clear")
            puts "Starlight Node Navigation"
            puts "uuid: #{node["uuid"]}"
            puts "Location: #{StartlightNodes::nodeToString(node)}"
            items = []
            StarlightNavigationAndBuilding::getStarlightNetworkChildNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network child] #{StartlightNodes::nodeToString(n)}", lambda{ StarlightNavigationAndBuilding::nagivateNode(n) }] }

            StarlightOwnershipClaims::getDataEntitiesForNode(node)
                .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] } # "creationTimestamp" is a common attribute of all data entities
                .each{|dataentity| items << ["[dataentity] #{DataEntities::dataEntityToString(dataentity)}", lambda{ DataEntities::nagivateDataEntity(dataentity) }] }

            StarlightNavigationAndBuilding::getStarlightNetworkParentNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network parent] #{StartlightNodes::nodeToString(n)}", lambda{ StarlightNavigationAndBuilding::nagivateNode(n) }] }
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # StarlightNavigationAndBuilding::navigation()
    def self.navigation()
        loop {
            system("clear")
            puts "Starlight Navigation"
            node = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
            break if node.nil?
            StarlightNavigationAndBuilding::nagivateNode(node)
        }
    end

end

class StarlightNodeNavigateOrSearchOrBuildAndSelect
    # StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
    def self.selectNodeOrNull()
        # Version 1
        # LucilleCore::selectEntityFromListOfEntitiesOrNull("node", StartlightNodes::nodes(), lambda {|node| StartlightNodes::nodeToString(node) })

        # Version 2
        nodestrings = StartlightNodes::nodes().map{|node| StartlightNodes::nodeToString(node) }
        nodestring = CatalystCommon::chooseALinePecoStyle("node:", [""]+nodestrings)
        StartlightNodes::nodes()
            .select{|node| StartlightNodes::nodeToString(node) == nodestring }
            .first
    end

    # StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodePossiblyMakeANewOneOrNull(canAskToMakeAParent)
    def self.selectNodePossiblyMakeANewOneOrNull(canAskToMakeAParent)
        node = StarlightNodeNavigateOrSearchOrBuildAndSelect::selectNodeOrNull()
        return node if node
        StartlightNodes::makeNodeInteractivelyOrNull(canAskToMakeAParent)
    end
end

