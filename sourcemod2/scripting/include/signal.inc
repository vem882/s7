#if defined _signal_included
  #endinput
#endif
#define _signal_included

/**
 * Sends a private message using Signal
 *
 * @param sourceName          The name of the source sending the PM (64 bytes max)
 * @param sourceId            The SteamID of the source sending the PM (32 bytes max)
 *                            (for automated sources, use "#server." followed by a short
 *                              lowercase name, for example "#server.bans")
 * @param destId              The SteamID to send the message to (32 bytes max)
 * @param message             The message - 256 bytes max
 * @noreturn
 */
native SendPrivateMessage(String:sourceName[], String:sourceId[], String:destId[], String:message[]);