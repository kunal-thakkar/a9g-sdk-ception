require "base.rb"
require "tracesniffer3G/tracesniffer.rb"

cwRegisterPlugin(File.dirname(__FILE__)+"/trace3Gplugin.dll")

module CWTraceSniffer3G

begin
    # Add a menu to control the Trace Sniffer.
    #cwAddMenuCommand("Trace Tool(3G)", "Start the Trace Tool", "sniffTraces()", 0)
    #cwAddMenuCommand("Trace Tool(3G)", "Stop the Trace Tool", "dontSniffTraces()", 0)
    #cwAddMenuCommand("Trace Tool(3G)", "", "", 0)
    
    # Some buttons?
    #cwAddToggleButton("TraceSnifferToolbar", "TraceSnifferEnabled", false, true, nil);
rescue #No CoolWatcher.
end

    def tsRunTraceButton()
        sniffTraces()
    end

    def tsStopTraceButton()
        sniffTracesEnable(0)
        dontSniffTraces()
    end

end

include CWTraceSniffer3G