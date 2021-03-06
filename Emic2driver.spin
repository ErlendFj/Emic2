{{ Emic2driver
 Erlend Fj. 2016
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Provides high level routines for driving the TTS chip Emic2
 Does not support RX i.e. will not read Emic replies, so calling routine has to insert pauses before next speak.
 A simple demo is embedded in the object, and that section can be commented out if memory space is precious.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
}}
{
 Acknowledgements:  

=======================================================================================================================================================================

 About                                                                                           '     VOICES                            EPSON CODES
 The Emic2 is a reasonable means to add speaking capabilities to projects.                       '  =============================    =============================
 More professional TTS modules cost five times as much.                                          '  0: Perfect Paul (Paulo)          \/  Decrease pitch              
 Simple TTS can be achieved by using the Epson codes, but if more advanced                       '  1: Huge Harry (Francisco)                                     
 intonation is required, DECtalk codes are better.                                               '  2: Beautiful Betty               /\  Increase pitch           
                                                                                                 '  3: Uppity Ursula                                                                  
                                                                                                 '  4: Doctor Dennis (Enrique)       >>  Increase speaking rate   
                                                                                                 '  5: Kit the Kid                                                
                                                                                                 '  6: Frail Frank                   <<  Decrease speaking rate   
                                                                                                 '  7: Rough Rita                                                 
                                                                                                 '  8: Whispering Wendy (Beatriz)    __  Emphasize the next word  
                                                                                                 '                                   
                                                                                                                                     ##  Whisper the next word    
 REF:                                                                                            '  SPECIAL CHARACTER ENTRY:                                                                 
 http://www.grandideastudio.com/emic-2-text-to-speech-module/                                    '  use "\x plus hex format char     :-) Select voice 


=======================================================================================================================================================================
}
 
CON

          _clkmode = xtal1 + pll16x
          _xinfreq = 5_000_000                                      'use 5MHz crystal
        
          clk_freq = (_clkmode >> 6) * _xinfreq                     'system freq as a constant
          mSec     = clk_freq / 1_000                               'ticks in 1ms
          uSec     = clk_freq / 1_000_000                           'ticks in 1us     (80 ticks)
          
          bitDur   = clk_freq / 9600                                'serial comms bit duration at 9600b/s

          
VAR
          BYTE  Sentence[128]                                        'To hold the text to be sent to Emic2                                    
          BYTE  NewSentence[128]

OBJ
          pst   : "Parallax Serial Terminal"
 
PUB Main  | ttsPIN, value, person, speed, loudness, pause                                         'Demo code (comment out if the space is needed)

     pst.Start(9600)                                                                              'Remember to start the terminal at 9600b/s
     WAITCNT(3*clkfreq + cnt)
     
     ttsPIN:= 16         '<= set pin number for demo here!
     Default(ttsPIN)
          
     BYTEMOVE(@Sentence, @DefaultSentence, StrSize(@DefaultSentence))                             'Copy default content into sentence

     pst.Str(String("Test of Emic2 - press Enter"))
     value := pst.DecIn
     pst.Chars(pst#NL, 2)
     pst.Chars(pst#NL, 2)
          
     REPEAT
       pst.Str(@Sentence)
       pst.Chars(pst#NL, 2)
       pst.StrInMax(@NewSentence, 128)
       IF StrSize(@NewSentence)> 1
         BYTEMOVE(@Sentence, @NewSentence, StrSize(@NewSentence))
         BYTE[@Sentence][StrSize(@NewSentence)]:= 0
    '   pst.Str(@Sentence)
       pst.Chars(pst#NL, 2)
       
       pst.Str(String("Choose voice (0 - 8) "))
       person := 0 #> pst.DecIn <# 9
       Voice(person, ttsPIN)    
       pst.Chars(pst#NL, 2)
       
       pst.Str(String("Choose rate (75 - 600) "))
       speed := 75 #> pst.DecIn <# 600
       Rate(speed, ttsPIN)     
       pst.Chars(pst#NL, 2)
       
       pst.Str(String("Choose volume ( -48 - 18) "))
       loudness := -48 #> pst.DecIn <# 18
       Volume(loudness, ttsPIN)       
       pst.Chars(pst#NL, 2)       

       pause:= Speak(@Sentence, ttsPIN)
       WAITCNT((pause*clkfreq) + cnt)
       pst.Chars(pst#NL, 2)
       pst.Str(String("-again-"))
       pst.Chars(pst#NL, 2)

       

PRI RandomPick(range) | rnd
  rnd := cnt?                                
  rnd := || rnd                              
  rnd := rnd/(2147483647/range)              
  RETURN rnd    


DAT                                                                                               

 DefaultSentence    BYTE    "__Hello world, let us talk.",0



'Application level functions
'=========================================================
PUB Speak(ptrText, PINtts)

   TxB(83, PINtts)                                                                               '"S" initiates tts
   TxStr(ptrText, PINtts)                                                                        'Transmit text string
   TxB(10, PINtts)                                                                               'and finish with a CR
   RETURN STRSIZE(ptrText)/10                                                                    'char count can be used to guesstimate wait delay
   

PUB Stop(PINtts)

   TxB(88, PINtts)                                                                               '"X" to stop
   

PUB PausePlay(PINtts)

   TxB(90, PINtts)                                                                               '"Z" to Pause, next time to play

   
PUB Voice(parVoice, PINtts)                                                                       '0 to 8

   TxB(78, PINtts)                                                                               '"N" to select voice
   TxB(parVoice + 48, PINtts)                                                                     'add 48 to convert voice to ASCII number
   TxB(10, PINtts)


PUB Volume(parVolume, PINtts) | vol                                                              '-48 to 18
     
   vol:= parVolume
   TxB(86, PINtts)                                                                               '"V" to select volume
   IF vol < 0
     TxB(45,PINtts)
     vol:= ||vol
   TxB( (vol / 10) + 48, PINtts  )    
   vol:= vol - 10*(vol / 10)
   TxB( vol + 48, PINtts)
   TxB(10, PINtts)                                     


PUB Rate(parRate, PINtts) | rte                                                                  '75 to 600

   rte:= parRate
   TxB(87, PINtts)                                                                               '"W" to select rate
   TxB((rte / 100) + 48, PINtts)
   rte/= 10 
   TxB((rte / 10) + 48, PINtts)
   rte/= 10 
   TxB(rte  + 48, PINtts)
   TxB(10, PINtts)                              


PUB Language(parLanguage, PINtts)                                                                '0 to 2

   TxB(76, PINtts)                                                                              '"L" to select language
   TxB(parLanguage + 48, PINtts)                                                                 'add 48 to convert language to ASCII number
   TxB(10, PINtts)


PUB Parser(parParser, PINtts)                                                                   '0=DECtalk, 1=Epson
                                                                                              
   TxB(80, PINtts)                                                                              '"N" to select parser
   TxB(parParser + 48, PINtts)                                                                  'add 48 to convert parser to ASCII number
   TxB(10, PINtts)


PUB Default(PINtts)

   TxB(82, PINtts)                                                                             '"R" to revert to default settings
   TxB(10, PINtts)




'Low level functions
'=========================================================
PRI TxStr(strAddr,txPin)
    REPEAT STRSIZE(strAddr)                                                                       'for each character in string
      TxB(BYTE[strAddr++],txPin)                                                                  'write the character


PRI TxB(txByte,txPin) | t
    txByte := (txByte | $100) << 1                                                                'add start bit, and OR in a stop bit
    OUTA[txPin] :=  1                                                                             'idle state                                                                     
    DIRA[txPin]~~                                                                                                                                                                
    t := CNT                                                                                      'sync                                                                           
    REPEAT 10                                                                                     'start + eight data bits + stop                                                 
      WAITCNT(t += bitDur)                                                                        'wait bit duration, first wait keeps 'idle state' for one bit duration          
      OUTA[txPin] := txByte                                                                       'output lsb,                                                                    
      txByte >>= 1                                                                                'then shift right to move next bit in place for tx                              
                                                                                                                                                                                  
                                                                                                                                                                                  
DAT                                                                                                                              

 


{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}