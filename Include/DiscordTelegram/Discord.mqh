//+------------------------------------------------------------------+
//|                                                     Discord.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Noel Martial Nguemechieu"
#property link      "http://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//|   Include                                                        |
//+------------------------------------------------------------------+
#include <Arrays\List.mqh>
#include <Arrays\ArrayString.mqh>



#include  <DiscordTelegram/snowflake.mqh>



//+--------------------------------
//+------------------------------------------------------------------+
//|   Defines                                                        |
//+------------------------------------------------------------------+
#define DISCORD_BASE_URL "https://www.discord.com/api/webhooks"

//+------------------------------------------------------------------+
//|   ENUM_CHAT_ACTION                                               |
//+------------------------------------------------------------------+

        


class DiscordCCustomMessage : public CObject
{
public:
   ulong  id;	//snowflake	unique id of the command	all
        bool type;//?	one of application command type	the type of command, defaults 1 if not set	all application_id	snowflake	unique id of the parent application	all
  ulong guild_id;//?	snowflake	guild id of the command, if not global	all
  string name;//	string	1-32 character name	all
string descriptions;//	string	1-100 character description for CHAT_INPUT commands, empty string for USER and MESSAGE commands	all
 string options;//?	array of application command option	the parameters for the command, max 25	CHAT_INPUT
bool default_permission;//?	boolean (default true)	whether the command is enabled by default when the app is added to a guild

  DiscordCCustomMessage()
   {
   
   
   
        id=12345;	//snowflake	unique id of the command	all
         type=1;//?	one of application command type	the type of command, defaults 1 if not set	all application_id	snowflake	unique id of the parent application	all
   guild_id=3456;//?	snowflake	guild id of the command, if not global	all
   name="";//	string	1-32 character name	all
descriptions="";//	string	1-100 character description for CHAT_INPUT commands, empty string for USER and MESSAGE commands	all
  options="";//?	array of application command option	the parameters for the command, max 25	CHAT_INPUT
default_permission=true;//?	boolean (default true)	whether the command is enabled by default when the app is added to a guild

   
   
   
   }

};

 