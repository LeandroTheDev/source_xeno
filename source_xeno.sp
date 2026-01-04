#include <sourcemod>
#include <geoip>

public Plugin myinfo =
{
    name        = "Source Xeno",
    author      = "LeandroTheDev",
    description = "Kick players from desired country",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/source_xeno"
};

#define MAX_BLOCKED_COUNTRIES 128
char g_BlockCountries[MAX_BLOCKED_COUNTRIES][4];
int  g_BlockCountryCount = 0;

#define MAX_BLOCKED_CITIES 128
char g_BlockCities[MAX_BLOCKED_CITIES][4];
int  g_BlockCityCount = 0;

public void OnPluginStart()
{
    char blockCountries[256];
    if (GetCommandLineParam("-blockCountries", blockCountries, sizeof(blockCountries)))
    {
        g_BlockCountryCount = ExplodeString(
            blockCountries,
            ",",
            g_BlockCountries,
            MAX_BLOCKED_COUNTRIES,
            sizeof(g_BlockCountries[]));

        if (g_BlockCountryCount > 0)
        {
            for (int i = 0; i < g_BlockCountryCount; i++)
            {
                TrimString(g_BlockCountries[i]);

                if (g_BlockCountries[i][0] == '\0')
                    continue;

                PrintToServer("[Source-Xeno] Blocked country [%d]: %s", i, g_BlockCountries[i]);
            }
        }
    }

    char blockCities[256];
    if (GetCommandLineParam("-blockCities", blockCities, sizeof(blockCities)))
    {
        g_BlockCityCount = ExplodeString(
            blockCities,
            ",",
            g_BlockCities,
            MAX_BLOCKED_COUNTRIES,
            sizeof(g_BlockCities[]));

        if (g_BlockCityCount > 0)
        {
            for (int i = 0; i < g_BlockCityCount; i++)
            {
                TrimString(g_BlockCities[i]);

                if (g_BlockCities[i][0] == '\0')
                    continue;

                PrintToServer("[Source-Xeno] Blocked city [%d]: %s", i, g_BlockCities[i]);
            }
        }
    }

    RegConsoleCmd("sm_xeno", ManulXeno, "Kick desired players from specific country or city");
}

public Action ManulXeno(int client, int args)
{
    if (!(CheckCommandAccess(client, "sm_xeno", ADMFLAG_BAN)))
    {
        PrintToServer("%d", GetUserFlagBits(client));
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_xeno <COUNTRY_CODE,COUNTRY_NAME,CITY_NAME>");
        return Plugin_Handled;
    }

    char value[128];
    GetCmdArg(1, value, sizeof(value));

    for (int xenoClient = 1; xenoClient <= MaxClients; xenoClient++)
    {
        if (!IsClientInGame(xenoClient))
            continue;

        char ip[64];
        GetClientIP(xenoClient, ip, sizeof(ip));

        ExecuteManualXenophobia(xenoClient, ip, value);
    }

    return Plugin_Handled;
}

public void OnClientConnected(int client)
{
    char ip[64];
    GetClientIP(client, ip, sizeof(ip));

    if (!StrEqual(ip, "127.0.0.1"))
        ExecuteXenophobia(client, ip);
}

// True if kicked, false otherwises
public bool ExecuteXenophobia(int client, const char[] ip)
{
    char country[128];
    GeoipCountry(ip, country, sizeof(country));
    TrimString(country);
    if (IsCountryBlocked(country))
    {
        KickClient(client, "This server does not allow: %s", country);
        return true;
    }
    char country2[3];
    GeoipCode2(ip, country2);
    if (IsCountryBlocked(country2))
    {
        KickClient(client, "This server does not allow: %s", country2);
        return true;
    }
    char country3[4];
    GeoipCode3(ip, country3);
    if (IsCountryBlocked(country3))
    {
        KickClient(client, "This server does not allow: %s", country3);
        return true;
    }
    char city[128];
    GeoipCity(ip, city, sizeof(city));
    TrimString(city);
    if (IsCityBlocked(city))
    {
        KickClient(client, "This server does not allow: %s", city);
        return true;
    }

    PrintToServer("[Source-Xeno] Client %d connecting with IP: %s, country: %s/%s/%s, city: %s", client, ip, country, country2, country3, city);
    return false;
}

// True if kicked, false otherwises, manual option
public bool ExecuteManualXenophobia(int client, const char[] ip, const char[] value)
{
    char country[128];
    GeoipCountry(ip, country, sizeof(country));
    TrimString(country);
    if (StrEqual(country, value, false))
    {
        KickClient(client, "This server does not allow: %s", country);
        return true;
    }
    char country2[3];
    GeoipCode2(ip, country2);
    if (StrEqual(country2, value, false))
    {
        KickClient(client, "This server does not allow: %s", country2);
        return true;
    }
    char country3[4];
    GeoipCode3(ip, country3);
    if (StrEqual(country3, value, false))
    {
        KickClient(client, "This server does not allow: %s", country3);
        return true;
    }
    char city[128];
    GeoipCity(ip, city, sizeof(city));
    TrimString(city);
    if (StrEqual(city, value, false))
    {
        KickClient(client, "This server does not allow: %s", city);
        return true;
    }

    return false;
}

stock bool IsCountryBlocked(const char[] country)
{
    // If there are no blocked countries, never block
    if (g_BlockCountryCount <= 0)
        return false;

    // If the client's country is empty (bot / GeoIP failed), ignore
    if (country[0] == '\0')
        return false;

    for (int i = 0; i < g_BlockCountryCount; i++)
    {
        // Never compare empty entries
        if (g_BlockCountries[i][0] == '\0')
            continue;

        if (StrEqual(country, g_BlockCountries[i], false))
            return true;
    }
    return false;
}

stock bool IsCityBlocked(const char[] city)
{
    // If there are no blocked cities, never block
    if (g_BlockCityCount <= 0)
        return false;

    // If the client's city is empty (bot / GeoIP failed), ignore
    if (city[0] == '\0')
        return false;

    for (int i = 0; i < g_BlockCityCount; i++)
    {
        // Never compare empty entries
        if (g_BlockCities[i][0] == '\0')
            continue;

        if (StrEqual(city, g_BlockCities[i], false))
            return true;
    }
    return false;
}