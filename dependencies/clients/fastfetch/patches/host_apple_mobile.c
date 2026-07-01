#include "host.h"
#include "common/sysctl.h"
#include "common/strutil.h"

const char* ffDetectHost(FFHostResult* host) {
    const char* error = ffSysctlGetString("hw.product", &host->family);
    if (error) {
        error = ffSysctlGetString("hw.model", &host->family);
    }
    if (error) {
        return error;
    }

    ffStrbufSetStatic(&host->name, ffHostGetMacProductNameWithHwModel(&host->family));
    if (host->name.length == 0) {
        ffStrbufSet(&host->name, &host->family);
    }

    /* IORegistry host probes (serial, UUID) are unavailable in the iOS sandbox. */
    return NULL;
}
