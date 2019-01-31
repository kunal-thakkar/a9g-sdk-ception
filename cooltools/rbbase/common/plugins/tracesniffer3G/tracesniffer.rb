require 'yaml'
require "base.rb"

if(!$TRACECONNECTION)
    $TRACECONNECTION = registerNewToolConnection(ToolConnection.new("Trace bypass"))
end

def $TRACECONNECTION.recreate()
    wasopen = @connection.open?()
    @connection.close()
    if($TRACEPLUGCONNECTION.empty?)
        @connection = CHEmptyConnection.new
    else
        @connection = CHBPConnection.new($TRACEPLUGCONNECTION, [0x80,0x81,0x83,0x86,0x8C,0x95])
    end
    @connection.setName(@name)
    begin
        @connection.open(false) if(wasopen)
        okputs "Connection #{@connection.name} (re)created (in %s state)." % ((wasopen)?("open"):("closed"))
        return true
    rescue Exception => e
        errputs "Connection #{@connection.name} could not be opened.<br> Reason: #{e.message} (#{e.class})."
        return false
    end    
end


module TraceSniffer

protected 

    @@colors = ["#800000","#008000","#000080",
                "#808000","#800080","#008080",
                "#600000","#006000","#000060",
                "#606000","#600060","#006060",
                "#700000","#007000","#000070",
                "#707000","#700070","#007070",
                "#500000","#005000","#000050",
                "#505000","#500050","#005050",
                "#400000","#004000","#000040",
                "#404000","#400040","#004040","#f000f0"]
    
    @@sxsTraceDesc = ["SXR", "PAL",  "L1A", "L1S",  "LAP", "RLU",  "RLD",
                      "LLC", "MM ",  "CC ", "SS ",  "SMS", "SM ",  "SND", "API",
                      "MMI", "SIM",  "AT ", "M2A",  "STT", "RRI",  "RRD", "RLP",
                      "HAL", "BCPU", "CSW", "EDRV", "MCI", "SVC1", "SVC2","T3G"]
    @@sxsTraceDesc3G = ["ATP", "DS",  "WD", "L1T",  "L1R", "L1M",  "MAC",                      
					"RLC", "PDCP",  "RRC", "RABM",  "RABVC", "MM ",  "TC", "CC",                      
					"SM", "SMS",  "SS", "MNS",  "SIM", "NVMEM",  "SLEEP", "UI",                      
					"SPY", "INTERRAT", "XPLORER", "SDMA","","",""];         

    begin
        require "tracesnifferxlconfig.rb"
    rescue Exception   
        @@sxsTraceLevelEnabled = { "CSW"=>true, "MMI"=>true }
    end
    
    @@sxsTraceLevelEnabledArray = @@sxsTraceDesc.collect{ |e| (@@sxsTraceLevelEnabled[e])?(true):(false) }
 
    @@sxsTraceLevelDesc = { "HAL" => ["WARN", "TIM",  "IO",  "RF",  "AU",  "LCD", "SD",  "CAM", 
                                      "SPI",  "UART", "USB", "VOC", "DMA", "SIM", "LPS", "DBG"],
    
                            "EDRV" => ["WARN", "PMD", "MEMD", "RFD", "AUD", "LCDD", "MCD", "CAMD", 
                                        "FMD", "BTD", "TSD",  "12",  "13",  "14",   "15",  "DBG"],
                            
                            "SVC1" => ["WARN", "AVCTLS", "AVPS",  "AVRS", "CAMS",    "FMG",  "FSS", "IMGS",
                                       "MPS",  "MRS",    "UCTLS", "UMSS", "UTRACES", "VOIS", "15", "16"],
                            "SVC2" => ["1", "2", "3", "4", "5", "GLS", "7", "8", "9", 
                                       "10", "11", "VPP", "13", "APS", "ARS", "DBG"],
    }

    @@lastTraceConfiguration        = [ [false]*16 ] * @@sxsTraceDesc.size
    @@lastTraceConfigurationOnReset = false
    @@lastTSPEnabled = false

    @@stringDatabase = nil

    @@withDate = false

    @@BILL = nil
	
    TID_POS         = 0
    TLEVEL_POS      = 5
    TDB_POS         = 12
    TID_MSK         = (0x1F << TID_POS)
    TLEVEL_MSK      = (0x0F << TLEVEL_POS)
    # !! warning only 16 bits of Id are transmitted, so upper bits present in the
    # embedded software are not usable in the trace tool
    
    def TGET_ID(id)
        ((id & TID_MSK) >> TID_POS) & 0xFF
    end
    
    def TGET_LEVEL(id)
        ((id & TLEVEL_MSK) >> TLEVEL_POS) & 0xFF
    end
    
    def ISTDB(id)
          ( ((id >> TDB_POS) & 1) == 1 )
    end

    def TOI32(arr)
        return (arr[3] << 24) | (arr[2] << 16) | (arr[1] << 8) | arr[0]
    end

    def dumpDesc(id)
        if(id>>15 == 1)
        	desc = @@sxsTraceDesc3G[TGET_ID(id)]
        	lvl = (id>>5)&0xFF
        	lvlStr = "%02d"%(lvl)
        else
        	desc = @@sxsTraceDesc[TGET_ID(id)]
        	lvl = TGET_LEVEL(id)
        	if desc
            lvlDesc = @@sxsTraceLevelDesc[desc]
            if lvlDesc
                lvlStr = lvlDesc[lvl]
            end
        	else
            desc = "?%02d"%TGET_ID(id)
        	end
        	if !lvlStr
            lvlStr = "%02d"%(lvl + 1)
        	end
        end
        desc + " " + lvlStr + " : "
    end
    
    def traceDesc(id)
        desc = @@sxsTraceDesc[TGET_ID(id)]
        lvl = TGET_LEVEL(id)
        if desc
            lvlDesc = @@sxsTraceLevelDesc[desc]
            if lvlDesc
                lvlStr = lvlDesc[lvl]
            end
        else
            desc = "?%02d"%TGET_ID(id)
        end
        if !lvlStr
            lvlStr = "%02d"%(lvl + 1)
        end
        desc + " " + lvlStr + " : "
    end
    
public

    def setTraceWithDate(b)
        @@withDate=b
    end    
  
    def printTrace(trace,id)
        #TODO : rescue when no CW
        include CWTraceSniffer3G
=begin
        color = @@colors[TGET_ID(id)]
        trace.strip!
        trace.gsub!(/&/,'&amp;')
        trace.gsub!(/</,'&lt;')
        trace.gsub!(/>/,'&gt;')
        trace.gsub!(/\n/,'<br>')
        #trace.gsub!(/\n/,'')
        trace.gsub!(/\r/,'')
        trace.gsub!(/\t/,'    ')
=end
        s=''
        if @@withDate
          s=Time.now.strftime('[%H:%M:%S] ')
        end
#       tputs s+"<font color=#{color}>" + traceDesc(id) + trace + "</font>"
#       gputs(0,s+"<font color=#{color}>" + traceDesc(id) + trace + "</font>")
	gputs(0,s+ traceDesc(id) + trace)
    end
    
    def dumpTrace(trace,id)
        #TODO : rescue when no CW
        include CWTraceSniffer3G

        s=''
        if @@withDate
          s=Time.now.strftime('[%H:%M:%S] ')
        end
        
	      gputs(0,s+ dumpDesc(id) + trace)
    end
    
    def treat3GTracePacket(a)
        include CWTraceSniffer3G  
        
        color = @@colors[30]  
        
        msgtype = a[2]
 
        if msgtype==0x20
            # diag_debug_message_info_t
            id = (a[1]<<8) | a[0]
            	#printf("id = 0x%x\n",id)
            if(ISTDB(id))
              b = a[0..15]
            	a = a[16..-1]
            	strnum=TOI32(a[0..3])
            	  #printf("strnum=0x%x\n",strnum)
            	if !@@stringDatabase
                printTrace("Database string not present (%#x)" % strnum ,id)
                return
            	end

            	argstr  = a[4..-1]
            	if !@@stringDatabase[strnum]
                printTrace("String not found in database (%#x)" % strnum ,id)
                return
            	end
            	str = @@stringDatabase[strnum].clone
            	newstr = str #not cloned here so gsub! will change it
            	begin
		            str.gsub!(/%([- #+0-9]*([bcdeEfgGiopsuxX]))|%([0-9]*l([xXudi])(y)?)|%(%)/) { |m|
		                if $6
		                    '%'
		                else
		                    if $2=='s'
		                        endofargstring = argstr.index(0)
		                        if(endofargstring == 0)
		                            thisArg = "";
		                        else
		                            thisArg = argstr[0..endofargstring-1].pack("C*")
		                        end
		                        argstr  = argstr[endofargstring+1..-1]              
		                    elsif $2=='d' or $2=='i' or $4=='d' or $4=="i"
		                        thisArg = TOI32(argstr[0..3])
		                        thisArg -= (thisArg & 0x80000000)*2;
		                        argstr  = argstr[4..-1]
		                    else
		                        thisArg = TOI32(argstr[0..3])
		                        argstr  = argstr[4..-1]
		                    end
		                    if $5 then
		                        # is an address or a symbol
		                        begin
		                            "%08x (%s)" % [thisArg, thisArg.functionAt]
		                        rescue Exception
		                            "%08x" % thisArg
		                        end
		                    else
		                        if $3 then
		                            m.to_s.gsub(/l/,'') % thisArg
		                        else
		                        m.to_s % thisArg
		                    		end
		                		end
                		end
            			}
		        rescue
		            newstr = "Couldn't parse parameters, str=\"#{ str }\" remaining [ #{argstr.collect() {|a| "%02X" % a}.join(" ")} ]"
		        end
            	b[3] = newstr.length + 14
            	msgHdr = b[0..15].pack("C*")
            	gputs(1, msgHdr + newstr)
      	      return
            else
	            length = a[3]
	            #endofstring = 0x7e            
	 
	            #indexofend  = a.index(endofstring)
	            if length == 0
	                puts "error! length=0"
	                return
	            end
	            len = length + 3
	            msg = a[0..len].pack("C*")
	            gputs(1, msg)
	            return 
	     end 
        end
        
        if msgtype==0xab  
           # IDC_UPDATE_UMTS_MSG  // UtsCmdWcdmaSignalingEvent_t
            if( a[0] != 0 || a[1] != 0)
            	puts "ab"
            	puts a
            	return
            end
            length = (a[19]<<8)|(a[18])            
            #endofstring = 0x7e
            #indexofend  = a.index(endofstring) 
            len = length + 18 + 4  
           
            msg = a[2..len].pack("C*")
            gputs(2,msg)   
            return         
        end
        
        if msgtype==0xad 
            # IDC_UPDATE_STATE_MSG // UtsCmdWcdmaStateEvent_t
            if( a[0] != 0 || a[1] != 0)
            	puts "ad"
            	puts a
            	return
            end
            length = a[3]
            endofstring = 0x7e            
            indexofend  = a.index(endofstring)   
                             
            msg = a[2..indexofend].pack("C*")
            gputs(3,msg)
             
            return         
        end 
        
        if msgtype==0xaf 
            # IDC_UPDATE_NAS_STATE_MSG  // UtsCmdWcdmaNasStateEvent_t
            length = a[3]
            endofstring = 0x7e            
            indexofend  = a.index(endofstring)   
                  
            msg = a[2..indexofend].pack("C*")
            gputs(4,msg)
              
            return         
        end        
    end
    
    def treatTracePacket(a)
        id = (a[1]<<8) | a[0]
        b = a[2..5]
        a = a[6..-1]
        
        if(!@@sxsTraceLevelEnabledArray[TGET_ID(id)])
           # puts "TRASH"
            return
        end
        
        if(ISTDB(id))
            strnum=TOI32(a[0..3])
            if !@@stringDatabase
                printTrace("Database string not present (%#x)" % strnum ,id)
                return
            end

            argstr  = a[4..-1]
            if !@@stringDatabase[strnum]
                printTrace("String not found in database (%#x)" % strnum ,id)
                return
            end
            str = @@stringDatabase[strnum].clone
        else
        
            endofstring = a.index(0)
            if(endofstring == nil)
                str = "String not terminated [ #{a.collect() {|e| "%02X" % e}.join(" ")} ]"
                argstr  = ""
            else
                str = a[0..endofstring-1].pack("C*")
                argstr  = a[endofstring+1..-1]
            end
        end
        
        newstr = str #not cloned here so gsub! will change it
        begin
            str.gsub!(/%([- #+0-9]*([bcdeEfgGiopsuxX]))|%([0-9]*l([xXudi])(y)?)|%(%)/) { |m|
                if $6
                    '%'
                else
                    if $2=='s'
                        endofargstring = argstr.index(0)
                        if(endofargstring == 0)
                            thisArg = "";
                        else
                            thisArg = argstr[0..endofargstring-1].pack("C*")
                        end
                        argstr  = argstr[endofargstring+1..-1]              
                    elsif $2=='d' or $2=='i' or $4=='d' or $4=="i"
                        thisArg = TOI32(argstr[0..3])
                        thisArg -= (thisArg & 0x80000000)*2;
                        argstr  = argstr[4..-1]
                    else
                        thisArg = TOI32(argstr[0..3])
                        argstr  = argstr[4..-1]
                    end
                    if $5 then
                        # is an address or a symbol
                        begin
                            "%08x (%s)" % [thisArg, thisArg.functionAt]
                        rescue Exception
                            "%08x" % thisArg
                        end
                    else
                        if $3 then
                            m.to_s.gsub(/l/,'') % thisArg
                        else
                        m.to_s % thisArg
                    end
                end
                end
            }
        rescue
            newstr = "Couldn't parse parameters, str=\"#{ str }\" remaining [ #{argstr.collect() {|a| "%02X" % a}.join(" ")} ]"
        end
				timeHdr = b[0..3].pack("C*")
        #printTrace( timeHdr + newstr, id)
        s=''
        if @@withDate
          s=Time.now.strftime('[%H:%M:%S] ')
        end
        gputs(5, timeHdr + traceDesc(id) + newstr)
    end
    
    def treatDumpPacket(a)
        id = (a[1]<<8) | a[0]
        size = (a[3]<<8) | a[2]
        if(a[4] != 37 || a[6] != 120 || a[7]!= 0)
           puts "Dump error: a[4]=%d, a[6]=%d, a[7]=%d" % [ a[4], a[6], a[7] ]
           return
        end
        
        if(a[5] != 50 && a[5] != 52 && a[5] != 56)
           puts "Dump error: a[5]=%d", a[5]
           return
        end
        	
        format = a[4..7].push(0).pack("c*").split("\000")[0]
        address = TOI32(a[8..11])
        
        # Jan. 28, 2010 - Hua Zeng - No junky bytes are seen by now. Already fixed at target side?
        #a = a[12..(-1-4)] #Remove 4 junky bytes at the end
        a = a[12..-1]
        
        if(size != a.length-1)
            puts "Dump error: size=%d, a len=%d" % [ size, a.length ]
            return
        end
        
        re = /^%?0?([248])([xX])?$/
        md = re.match(format)
        if (md[2] == nil)
            x = "x"
        else
            x = md[2]
        end
        
        case md[1]
            when "2"
                decoded = a.collect() { |k| "%02#{x}" % k }.join(" ")
            when "4"
                b = a.collect() { |k| "%02#{x}" % k }
                c=[]
                while(b.size>0)
                    tzwei = b.shift
                    einz = b.shift
                    einz = "00" if(!einz)
                    c << einz+tzwei
                end    
                decoded = c.join(" ")
                if( (size*2 + size/2 +4) != decoded.length)
                    puts "Dump error: size=%d, decoded len=%d" % [ size, decoded.length ]
                    return
                end
            when "8"
                b = a.collect() { |k| "%02#{x}" % k }
                c=[]
                while(b.size>0)
                    t0 = b.shift
                    t1 = b.shift
                    t2 = b.shift
                    t3 = b.shift
                    t1 = "00" if(!t1)
                    t2 = "00" if(!t2)
                    t3 = "00" if(!t3)
                    c << t3+t2+t1+t0
                end
                decoded = c.join(" ")
            else
                decoded = "FORMAT UNKNOWN: #{ format }"
        end
              
        dumpTrace( ("Dump : at 0x%08X (%d/%d) : " % [address, size, a.length]) + decoded ,id)
    end

    def treatTimeStampPacket(a)
        return if(!@@lastTSPEnabled)
        fn = TOI32(a)
        
        msgLost = ""
=begin #ifndef SXS_RMT_TRACE_DATA_LOST_NUM
        if((fn & (1<<31)) != 0 )
            msgLost = " [ Msg Loss Detected ]"
            fn &= ~(1<<31);
        end
=end
        if((fn & (0xff<<24)) != 0 )
            msgLost = " - [ %03d msgs lost ]" % [(fn & (0xff<<24)) >> 24]
            fn &= ~(0xff<<24);
        end
        
        trace = "Fn %07d T1 %04d T2 %02d T3 %02d" % [fn, fn/1326, fn%26, fn%51]
        s=''
        if @@withDate
          s=Time.now.strftime('[%H:%M:%S] ')
        end
        #tputs s+"TSP : "+trace+msgLost
        gputs(0, s+"TSP : "+trace+msgLost)
    end
    
    def setTraceLevel(id,bitmask16)
        packet = [id,0,bitmask16 & 0xFF, (bitmask16>>8) & 0xFF]
        $TRACECONNECTION.connection.sendPacket(0x86,packet)
    end

    def setTraceLevel3g(addr,value)
    		Integer.w8(addr,value)
    end
    
    def setTraceLevelMask3g(addr,value)
    		Integer.w32(addr,value)
    end
   
=begin    
    def setTraceLevel3g(offset,value)
    		puts "hanhui set trace"
    		if(!$wd_mailbox.nil?)
    				traceLevelPtr = $wd_mailbox.WDDbg_Trace_Level
    				printf("hanhui traceLevelPtr = 0x%x", traceLevelPtr.RU)
        		#$TRACECONNECTION.connection.write8(traceLevelPtr + offset,value)
        end
    end 
=end  
    def makeSureTraceHandleIsOpen(force=false)
        
        if(force)
            success = $TRACECONNECTION.recreate()
            sleep(0.1)
            return false if(!success)
        end
        
        begin
            $TRACECONNECTION.connection.open(false) if(!$TRACECONNECTION.connection.open?())
        rescue Exception => e
            return false
        end
        return true
    end

    # flow control flag
    SXS_HOLD_RX  =  (1 << 0)
	  SXS_RELEASE_RX =(1 << 1)
	  SXS_HOLD_TX =   (1 << 2)
	  SXS_RELEASE_TX = (1 << 3)
	    
    def sniffTracesEnable(flag)
        if($TRACECONNECTION.connection.open?())
	    if(flag == 0)
	        bitmap = SXS_HOLD_TX
	    elsif(flag == 1)
	        bitmap = SXS_RELEASE_TX
	    else
                bitmap = SXS_RELEASE_TX
	    end
	
            packet = [0,1,bitmap,0]
            $TRACECONNECTION.connection.sendPacket(0x86,packet)
        end  
    end

    def sniffTraces()
        if(@@BILL && @@BILL.alive?())
            sniffTracesEnable(1)
            puts "TRACE SNIFFING ALREADY RUNNING"
            return
        end
        
        if(!makeSureTraceHandleIsOpen(true)) #BE VIOLENT
            wputs "The tracetool will not work properly, no working device is currently connected to the tool."                        
            return
        end
	
        #reapplyTraceConfiguration()
        sniffTracesEnable(1)
        
        @@BILL = Thread.new {
           dead = false
           okputs "TRACE SNIFFING ON."
           begin
              loop {
                  begin
                    begin
                        a = $TRACECONNECTION.connection.getPacket(0)
                    rescue CHBPConnectionTimeout  
                        sleep 0.01 
                        #Sleep when there ain't no packets  
                        redo
                    end
                    
                    if(dead)
                        dead = false
                        okputs "TRACE TOOL RESURRECTED"
                    end
                    
                    case a[0] #switch on flowid
                        when 0x80
                            treatTracePacket(a[1])
                        when 0x81
                            treatDumpPacket(a[1])
                        when 0x83
                            treatTimeStampPacket(a[1])
                        when 0x86
                            puts "GNEUH"
                            #Works only from host to target
                        when 0x8C
                            if(sendTraceConfigurationOnReset?())
                                #tputs "<font color=red>**** REAPPLYING TRACE CONFIGURATION ON RESET ****</font>"
                                tputs "**** REAPPLYING TRACE CONFIGURATION ON RESET ****\n" 
                                reapplyTraceConfiguration()
                            else
                                #tputs "<font color=red>==== TRACE CONFIGURATION NOT REAPPLIED ON RESET ====</font>"
                                tputs "==== TRACE CONFIGURATION NOT REAPPLIED ON RESET ====\n"
                            end
                            sniffTracesEnable(1)
                        when 0x95
                            treat3GTracePacket(a[1])
                    end
                    
                  rescue NotConnectedError, UnvalidHandleError
                    if(!dead)  
                        errputs "DISCONNECTED. TRACE TOOL STOPPED."
                        dead = true
                    end
                    sleep 1.0
                  rescue Exception => e
                    puts a
                    errputs "Error in trace tool. Detail follows."
                    CRExceptionPrint e
                    errputs "Trace tool stopped on error."                   
                    return
                  ensure
                    
                  end
                  
              }
          ensure
            #This will clean all residues and stop coolhost sending traces on the handle
            $TRACECONNECTION.connection.close
            wputs "TRACE SNIFFING OFF."
          end
        }
    end

    def dontSniffTraces()           
        sniffTracesEnable(0)
        if(@@BILL && @@BILL.alive?)
            @@BILL.kill
            @@BILL = nil
            puts "TRACE SNIFFING STOPPED NOW."
        end
    end

    def setupTraceLevelGui()
        setTraceWidgetMaximum 100000
        setTraceNames(@@sxsTraceDesc)
        @@sxsTraceLevelDesc.each{ |k,v|
            setTraceLevelNames(@@sxsTraceDesc.index(k),v)
        }
        @@sxsTraceLevelEnabled.each{ |k,v| 
            setTraceLevelEnabled(@@sxsTraceDesc.index(k),v)
        }
    end

    
    def setTraceConfiguration(arrayofarrayofbool,tspenabled,restartonreset)
        @@lastTraceConfiguration        = arrayofarrayofbool
        @@lastTraceConfigurationOnReset = restartonreset
        @@lastTSPEnabled                = tspenabled    
    end
    
    def applyTraceConfiguration(arrayofarrayofbool,tspenabled,restartonreset)
        return if(!makeSureTraceHandleIsOpen())
        puts "2g Setting trace levels."

        i = 0
        arrayofarrayofbool.each{ |ba|
            mask = 0
            j = 0
            ba.each{ |b|
                mask |= (b)?(1<<j):(0)
                j += 1
            }
            setTraceLevel(i,mask)
            i += 1
        }
        @@lastTraceConfiguration        = arrayofarrayofbool
        @@lastTraceConfigurationOnReset = restartonreset
        @@lastTSPEnabled = tspenabled

    end
    
    def reapplyTraceConfiguration()
        applyTraceConfiguration(@@lastTraceConfiguration,@@lastTSPEnabled,@@lastTraceConfigurationOnReset)
    end
       
    def applyTraceConfiguration3g(levelarray,bitarray)
        return if(!makeSureTraceHandleIsOpen())
        puts "3g Setting trace levels."
    		if(!$wd_mailbox.nil?)
    				traceLevelPtr = $wd_mailbox.WDDbg_Trace_Level
    				printf("traceLevelPtr = 0x%x", traceLevelPtr.RU)
    		end
    		return if(traceLevelPtr == 0)
        #puts levelarray
        #puts bitarray
       
				i = 0
        levelarray.each{ |v|
            setTraceLevel3g(traceLevelPtr.RU + 26 + i,v)
            #puts v
            i += 1
        }
        
        j = 0
        bitmask = 0
        bitarray.each{ |v|
            bitmask |= v<<j
            #puts v
            j += 1
        }
        #printf("bitmask = 0x%x\n", bitmask)
        setTraceLevelMask3g(traceLevelPtr.RU + 26 + i,bitmask)
        #@@lastlevelarray = levelarray
        #@@lastbitarray = bitarray
    end
    
    def reapplyTraceConfiguration3g()
        #applyTraceConfiguration3g(@@lastlevelarray,@@lastTSPEnabled,@@lastTraceConfigurationOnReset)
    end

    def loadTraceDb()
        #yaml_file = $TOOLPOOL + '/map/ChipStd/traceDb.yaml'
        pathToTraceDB = cwGetProfileEntry("pathToTraceDB","")
        puts "Loading TraceTool TraceDB ..."
        yaml_file = pathToTraceDB + '/traceDb.yaml';
        
        begin
            File.open( yaml_file, 'r' ) do |input|
                @@stringDatabase = YAML::load( input )
            end
        rescue Errno::ENOENT
            puts "*** Warning : String database not found!"
        end
    end
    
    def sendTraceConfigurationOnReset?()
        return @@lastTraceConfigurationOnReset
    end
    
    def tspTraceEnabled?()
        return @@lastTSPEnabled
    end

    def getTraceBufferInfo(mapfile)
        begin
            file = File.new(mapfile, "r")
        rescue => detail
            puts "Failed to open #{mapfile}: %s" % detail.to_str()
            return [nil, nil]
        end
        
        last_line = nil
        file.each { |line|
            addr = line[/^\s*0[xX][fF]{8}([0-9a-fA-F]{8})\s+sxs_Rmt\s*$/, 1]
            if (addr != nil)
                file.close()
                size = last_line[/^\s*\S+\s+0[xX][fF]{8}[0-9a-fA-F]{8}\s+(0[xX][0-9a-fA-F]+)\s*/, 1]
                return [addr.hex() & 0x00FFFFFF, size.hex()]
            end
            last_line = line
        }
        
        file.close()
        return [nil, nil]
    end
    
    def getTraceBufferInfo3(mapfile)
        begin
            file = File.new(mapfile, "r")
        rescue => detail
            puts "Failed to open #{mapfile}: %s" % detail.to_str()
            return [nil, nil]
        end
        
        last_line = nil
        file.each { |line|
            addr = line[/^\s*0[xX][fF]{8}([0-9a-fA-F]{8})\s+wd_Rmt\s*$/, 1]
            if (addr != nil)
                file.close()
                size = last_line[/^\s*\S+\s+0[xX][fF]{8}[0-9a-fA-F]{8}\s+(0[xX][0-9a-fA-F]+)\s*/, 1]
                return [addr.hex() & 0x00FFFFFF, size.hex()]
            end
            last_line = line
        }
        
        file.close()
        return [nil, nil]
    end
            
    SXS_RMT_START_FRM = 0xad
    TRACE_BUF_SIZE_MASK = (0x400 - 1)
    INDICES_SIZE = 0x1c
    
    def findTraceFrameStartIndex(buf,idx)
        if (buf[idx] == SXS_RMT_START_FRM)
            return idx
        end

        idx += 1
        while (idx+3 < @trace_buf_size)
            if (buf[idx] == SXS_RMT_START_FRM)
                len = (buf[idx+1] << 8) | buf[idx+2]
                if (len >= 4 && idx+3+len+1 < @trace_buf_size)
                    flow_id = buf[idx+3]
                    if (flow_id == 0x80 || flow_id == 0x81 || flow_id == 0x83)
                        offset_idx = idx+3+len
                        next_offset = buf[offset_idx]
                        if ( next_offset == 0 ||
                            (offset_idx+next_offset < @trace_buf_size && buf[offset_idx+next_offset] == SXS_RMT_START_FRM) )
                            return offset_idx+next_offset
                        end
                    end
                end
            end
            idx += 1
        end
        
        return idx
    end

    DEFAULT_SRAM_BIN_FILE = "sram.bin"
    
    def parseTraceInFile(binFile=DEFAULT_SRAM_BIN_FILE, lodMapFile=nil,
                           traceOffsetInBin=nil, traceSizeInBin=nil,
                           startIdx=nil, endIdx=nil,
                           traceBufFmt=false)
        if (lodMapFile == nil)
            if (traceOffsetInBin == nil || traceSizeInBin == nil)
                traceOffsetInBin = 0
                traceSizeInBin = File.size(binFile)
            end
        else
            if (!traceBufFmt)
                raise "The map file should be used with trace buffer format"
                return
            end

            info = getTraceBufferInfo(lodMapFile)
            traceOffsetInBin = info[0]
            traceSizeInBin = info[1]
            if (traceOffsetInBin == nil || traceSizeInBin == nil)
                raise "Failed to get trace offset from #{lodMapFile}"
                return
            end
        end
        
        if (traceBufFmt)
            @trace_buf_size = traceSizeInBin & ~TRACE_BUF_SIZE_MASK
            if ((startIdx == nil || endIdx == nil) &&
                    (@trace_buf_size + INDICES_SIZE > traceSizeInBin))
                raise "No indices information in #{binFile}"
                return
            end
        else
            @trace_buf_size = traceSizeInBin
            startIdx = 0
            endIdx = 0
        end

        begin
            file = File.new(binFile, "r")
        rescue => detail
            puts "Failed to open %s: %s" % [ binFile, detail.to_str() ]
            return
        end
        begin
            file.binmode()
            file.seek(traceOffsetInBin, IO::SEEK_SET)
            read_len = traceSizeInBin
            buf = file.read(read_len)
        rescue => detail
            file.close()
            puts "Failed to read %s: %s" % [ binFile, detail.to_str() ]
            return
        end
        file.close()
        
        puts "Read 0x%04x bytes from %s @ offset 0x%08x" % [ buf.length(), binFile, traceOffsetInBin ]
        
        if (startIdx == nil || endIdx == nil)
            wIdx    = buf[@trace_buf_size]   | (buf[@trace_buf_size+1] << 8)
            rIdx    = buf[@trace_buf_size+2] | (buf[@trace_buf_size+3] << 8)
            #nextIdx = buf[@trace_buf_size+4] | (buf[@trace_buf_size+5] << 8)

            puts "BufSzie=0x%04x, WIdx=0x%04x, RIdx=0x%04x" % [ @trace_buf_size, wIdx, rIdx ]
        
            suspended = buf[@trace_buf_size+6]
            savedRIdx = buf[@trace_buf_size+0x1a] | (buf[@trace_buf_size+0x1b] << 8)
            if (suspended != 0)
                rIdx = savedRIdx
                puts "suspened=%d, savedRIdx=0x%04x, using savedRIdx" % [ suspended, savedRIdx ]
            end
        else
            wIdx = endIdx
            rIdx = startIdx
        end

        # enable all traces
        #@@sxsTraceLevelEnabledArray = [ true ] * @@sxsTraceDesc.size
        
        idx = 0;
        crc_detection = 0;
        crc_len = 0;
        while (1)
            if (idx+3 >= @trace_buf_size)
                puts "Out of buffer idx=0x%04x" % idx
                return
            end            
          
            if (buf[idx] == SXS_RMT_START_FRM)
                len = (buf[idx+1] << 8) | buf[idx+2]
                if (len < 4 || idx+3+len+1 > @trace_buf_size)
                    puts "Out of buffer: idx=0x%04x, len=0x%04x" % [ idx, len ]
                    return
                end
                
                flow_id = buf[idx+3]
                trace_content = []
                tmp = buf[idx+4..idx+3+len-1]
                tmp.each_byte() { |c| trace_content << c }
                
                case flow_id #switch on flowid
                    when 0x80
                        treatTracePacket(trace_content)
                    when 0x81
                        treatDumpPacket(trace_content)
                    when 0x83
                        treatTimeStampPacket(trace_content)
                    when 0x95
                        treat3GTracePacket(trace_content)
                    else
                        tputs "<font color=red>**** Unknown Flow ID: 0x%02x @ idx=0x%04x ****</font>" % [ flow_id, idx ]
                end
                
                prev_idx = idx
                
                if (traceBufFmt)
                    offset_idx = idx+3+len          # header: 3 bytes
                    next_offset = buf[offset_idx]   # next header offset value
                    idx = offset_idx+next_offset
                    
                    if (prev_idx < rIdx && rIdx <= idx)
                        tputs ""
                        tputs "<font color=red>---- Start of Traces NOT Yet Sent to Host ----</font>"
                        tputs ""
                    end
                    
                    if (prev_idx < wIdx && wIdx <= idx)
                        tputs ""
                        tputs "<font color=red>---- End of Most Recent Traces ----</font>" % idx
                        tputs ""
                        if (rIdx > wIdx)
                            tputs ""
                            tputs "<font color=red>---- Start of Traces NOT Sent to Host Yet ----</font>"
                            tputs ""
                            idx = findTraceFrameStartIndex(buf, rIdx)
                            next_offset = -1
                        end
                    end
                    
                    if (next_offset == 0)
                        puts "End of trace: idx=0x%04x" % idx
                        return
                    end
                else
                    # There might be a CRC in the tail
                    idx += 3+len+crc_len   # header: 3 bytes, tail CRC: 1 or 0 byte
                    if (crc_detection == 0)
                        crc_detection = 1;
                        if (buf[idx] != SXS_RMT_START_FRM && buf[idx+1] == SXS_RMT_START_FRM)
                            crc_len = 1;
                            idx += 1;
                            puts "Tail CRC detected"
                        end
                    end
                end
            else
                puts "Bad header: idx=0x%04x, content=0x%02x" % [ idx, buf[idx] ]
                idx += 1
            end
        end
    end
    
    def parseTraceInFile3(binFile=DEFAULT_SRAM_BIN_FILE, lodMapFile=nil,
                           traceOffsetInBin=nil, traceSizeInBin=nil,
                           startIdx=nil, endIdx=nil,
                           traceBufFmt=true)
        if (lodMapFile == nil)
            if (traceOffsetInBin == nil || traceSizeInBin == nil)
                traceOffsetInBin = 0
                traceSizeInBin = File.size(binFile)
            end
        else
            if (!traceBufFmt)
                raise "The map file should be used with trace buffer format"
                return
            end

            info = getTraceBufferInfo3(lodMapFile)
            traceOffsetInBin = info[0]
            traceSizeInBin = info[1]
            if (traceOffsetInBin == nil || traceSizeInBin == nil)
                raise "Failed to get trace offset from #{lodMapFile}"
                return
            end
        end
        
        if (traceBufFmt)
            @trace_buf_size = traceSizeInBin & ~TRACE_BUF_SIZE_MASK
            if ((startIdx == nil || endIdx == nil) &&
                    (@trace_buf_size + INDICES_SIZE > traceSizeInBin))
                raise "No indices information in #{binFile}"
                return
            end
        else
            @trace_buf_size = traceSizeInBin
            startIdx = 0
            endIdx = 0
        end

        begin
            file = File.new(binFile, "r")
        rescue => detail
            puts "Failed to open %s: %s" % [ binFile, detail.to_str() ]
            return
        end
        begin
            file.binmode()
            file.seek(traceOffsetInBin, IO::SEEK_SET)
            read_len = traceSizeInBin
            buf = file.read(read_len)
        rescue => detail
            file.close()
            puts "Failed to read %s: %s" % [ binFile, detail.to_str() ]
            return
        end
        file.close()
        
        puts "Read 0x%04x bytes from %s @ offset 0x%08x" % [ buf.length(), binFile, traceOffsetInBin ]
        
        if (startIdx == nil || endIdx == nil)
            wIdx    = buf[@trace_buf_size]   | (buf[@trace_buf_size+1] << 8)
            rIdx    = buf[@trace_buf_size+2] | (buf[@trace_buf_size+3] << 8)
            #nextIdx = buf[@trace_buf_size+4] | (buf[@trace_buf_size+5] << 8)

            puts "BufSzie=0x%04x, WIdx=0x%04x, RIdx=0x%04x" % [ @trace_buf_size, wIdx, rIdx ]
        
            suspended = buf[@trace_buf_size+6]
            savedRIdx = buf[@trace_buf_size+0x1a] | (buf[@trace_buf_size+0x1b] << 8)
            if (suspended != 0)
                rIdx = savedRIdx
                puts "suspened=%d, savedRIdx=0x%04x, using savedRIdx" % [ suspended, savedRIdx ]
            end
        else
            wIdx = endIdx
            rIdx = startIdx
        end

        # enable all traces
        #@@sxsTraceLevelEnabledArray = [ true ] * @@sxsTraceDesc.size
        
        idx = 0;
        crc_detection = 0;
        crc_len = 0;
        while (1)
            if (idx+3 >= @trace_buf_size)
                puts "Out of buffer idx=0x%04x" % idx
                return
            end            
          
            if (buf[idx] == SXS_RMT_START_FRM)
                len = (buf[idx+1] << 8) | buf[idx+2]
                if (len < 4 || idx+3+len+1 >= @trace_buf_size)
                    puts "Out of buffer: idx=0x%04x, len=0x%04x" % [ idx, len ]
                    return
                end
                
                flow_id = buf[idx+3]
                trace_content = []
                tmp = buf[idx+4..idx+3+len-1]
                tmp.each_byte() { |c| trace_content << c }
                
                case flow_id #switch on flowid
                    when 0x80
                        treatTracePacket(trace_content)
                    when 0x81
                        treatDumpPacket(trace_content)
                    when 0x83
                        treatTimeStampPacket(trace_content)
                    when 0x95
                        treat3GTracePacket(trace_content)
                    else
                        tputs "<font color=red>**** Unknown Flow ID: 0x%02x @ idx=0x%04x ****</font>" % [ flow_id, idx ]
                end
                
                prev_idx = idx
                
                if (traceBufFmt)
                    offset_idx = idx+3+len          # header: 3 bytes
                    next_offset = buf[offset_idx]   # next header offset value
                    idx = offset_idx+next_offset
                    
                    if (prev_idx < rIdx && rIdx <= idx)
                        tputs ""
                        tputs "<font color=red>---- Start of Traces NOT Yet Sent to Host ----</font>"
                        tputs ""
                    end
                    
                    if (prev_idx < wIdx && wIdx <= idx)
                        tputs ""
                        tputs "<font color=red>---- End of Most Recent Traces ----</font>" % idx
                        tputs ""
                        if (rIdx > wIdx)
                            tputs ""
                            tputs "<font color=red>---- Start of Traces NOT Sent to Host Yet ----</font>"
                            tputs ""
                            idx = findTraceFrameStartIndex(buf, rIdx)
                            next_offset = -1
                        end
                    end
                    
                    if (next_offset == 0)
                        puts "End of trace: idx=0x%04x" % idx
                        return
                    end
                else
                    # There might be a CRC in the tail
                    idx += 3+len+crc_len   # header: 3 bytes, tail CRC: 1 or 0 byte
                    if (crc_detection == 0)
                        crc_detection = 1;
                        if (buf[idx] != SXS_RMT_START_FRM && buf[idx+1] == SXS_RMT_START_FRM)
                            crc_len = 1;
                            idx += 1;
                            puts "Tail CRC detected"
                        end
                    end
                end
            else
                puts "Bad header: idx=0x%04x, content=0x%02x" % [ idx, buf[idx] ]
                idx += 1
            end
        end
    end

end

include TraceSniffer
loadTraceDb()

addHelpEntry("chip", "parseTraceInMemFile0", "", "",
    "Parse trace in a dumped memory binary file, \"#{DEFAULT_SRAM_BIN_FILE}\".")
def parseTraceInMemFile0()
    TraceSniffer::parseTraceInFile()
end

addHelpEntry("chip", "parseTraceInMemFile1", "sramBinFile", "",
    "Parse trace in a dumped memory binary file, 'sramBinFile'.")
def parseTraceInMemFile1(sramBinFile)
    setTraceWidgetMaximum 2000000
    TraceSniffer::parseTraceInFile(sramBinFile)
end

addHelpEntry("chip", "startTrace", "", "",
    "Start trace.")
def startTrace()
    tsRunTraceButton()
end

addHelpEntry("chip", "stopTrace", "", "",
    "Start trace.")
def stopTrace()
    tsStopTraceButton()
end

addHelpEntry("chip", "save3GTrace", "path", "",
    "Save trace in given path, 'path'.")
def save3GTrace(path)
    startSave3GTrace(path)
end

addHelpEntry("chip", "stopWrite", "", "",
    "Stop write trace to file.")
def stopWrite()
    stopSave3GTrace()
end

addHelpEntry("chip", "parseTraceInMemFile2", "sramBinFile, lodMapFile", "",
    "Parse trace in a dumped memory binary file, 'sramBinFile', based on the map file, 'lodMapFile'.")
def parseTraceInMemFile2(sramBinFile, lodMapFile)
    TraceSniffer::parseTraceInFile(sramBinFile, lodMapFile)
end

addHelpEntry("chip", "parseTraceInMemFile3", "sramBinFile, lodMapFile", "",
    "Parse trace in a dumped memory binary file, 'sramBinFile', based on the map file, 'lodMapFile'.")
def parseTraceInMemFile3(sramBinFile, lodMapFile)
    TraceSniffer::parseTraceInFile3(sramBinFile, lodMapFile)
end

addHelpEntry("chip", "parseTraceInMemFile5", "sramBinFile, offset, size, startIdx, endIdx", "",
    "Parse trace in a dumped memory binary file, 'sramBinFile'. The trace buffer locates at 'offset', and its size is 'size'. Within the trace buffer, the trace starts at 'startIdx', and ends at 'endIdx'.")
def parseTraceInMemFile5(sramBinFile, offset, size, startIdx, endIdx)
    TraceSniffer::parseTraceInFile(sramBinFile, nil, offset, size, startIdx, endIdx)
end

addHelpEntry("chip", "parseTraceInCapturedFile1", "capBinFile", "",
    "Parse trace in a captured binary file, 'capBinFile'.")
def parseTraceInCapturedFile1(capBinFile)
    TraceSniffer::parseTraceInFile(capBinFile, nil, nil, nil, nil, nil, false)
end
