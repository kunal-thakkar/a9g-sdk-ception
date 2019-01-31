

module TraceSniffer3GPlugin

    @@traceSniffer3GActivated = false

    def TraceSniffer3GPlugin.activateTraceSniffer3GGui

        if (@@traceSniffer3GActivated == false)
            puts "Loading TraceTool GUI ..."
            
            #We need the path to be set before we require anything
            load "tracesniffer3G/tracesniffergui.rb"

            @@traceSniffer3GActivated = true
            puts "TraceTool GUI loaded."
        else
            puts "TraceTool GUI already loaded."
        end
    end
end


#CoolWatcher specific
begin
    include CoolWatcher

    def activateTraceSniffer3GGui
        TraceSniffer3GPlugin::activateTraceSniffer3GGui()
        setupTraceLevelGui()
        
        defaulttfg = "rbbase/common/plugins/tracesniffer3G/default.tfg"
        entry = cwGetProfileEntry("defaultTfg","")
        
        if(entry=="")
           cwSetProfileEntry("defaultTfg",defaulttfg)
           entry = defaulttfg 
        end
        
        loadTraceConfig(entry)
        
        sniffTraces()
    end
    
    begin
        cwAddMenuCommand("Plugins", "Activate TraceTool(3G)","activateTraceSniffer3GGui()",0) if(!$enterprisever)
    rescue Exception
        puts "*** TraceTool not present. TraceTool unavailable ***"
    end
    
rescue Exception
end

