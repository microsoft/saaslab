
using System;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;


namespace UserPortal.Telemetry
{
    /*
     * Custom TelemetryInitializer that adds tenant to telemetry
     *
     */
    public class TelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            var requestTelemetry = telemetry as RequestTelemetry;
            // Is this a TrackRequest() ?
            if (requestTelemetry == null) return;

            // Would normally retrieve the Tenant details from the User.Claims
            requestTelemetry.Properties["TenantId"] = "123456";
            requestTelemetry.Properties["TenantName"] = "Slob Socks";
        }
    }
}