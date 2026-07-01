#include "os.h"
#include "common/sysctl.h"
#include "common/strutil.h"

#include <TargetConditionals.h>

void ffDetectOSImpl(FFOSResult* os) {
#if TARGET_OS_IPHONE
    ffStrbufSetStatic(&os->id, "ios");
    ffStrbufSetStatic(&os->name, "iOS");
#else
    ffStrbufSetStatic(&os->id, "apple-mobile");
    ffStrbufSetStatic(&os->name, "Apple mobile");
#endif

    ffSysctlGetString("kern.osproductversion", &os->version);
    ffSysctlGetString("kern.osversion", &os->buildID);

    ffStrbufAppend(&os->versionID, &os->version);

    if (os->version.length > 0) {
        ffStrbufSetF(&os->prettyName, "%s %s (%s)", os->name.chars, os->version.chars, os->buildID.chars);
    } else {
        ffStrbufSet(&os->prettyName, &os->name);
    }
}
