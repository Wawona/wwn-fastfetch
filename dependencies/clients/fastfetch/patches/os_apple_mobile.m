#include "os.h"
#include "common/sysctl.h"
#include "common/strutil.h"

#include <TargetConditionals.h>

/*
 * Sandbox-safe OS detection for Apple mobile. Reports the correct platform
 * label per target. iPadOS and iOS share TARGET_OS_IPHONE, so they are split
 * at runtime by the hw.machine prefix ("iPad" vs "iPhone"/"iPod").
 */
void ffDetectOSImpl(FFOSResult* os) {
#if defined(TARGET_OS_WATCH) && TARGET_OS_WATCH
    ffStrbufSetStatic(&os->id, "watchos");
    ffStrbufSetStatic(&os->name, "watchOS");
#elif defined(TARGET_OS_TV) && TARGET_OS_TV
    ffStrbufSetStatic(&os->id, "tvos");
    ffStrbufSetStatic(&os->name, "tvOS");
#elif defined(TARGET_OS_VISION) && TARGET_OS_VISION
    ffStrbufSetStatic(&os->id, "visionos");
    ffStrbufSetStatic(&os->name, "visionOS");
#elif defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
    {
        FF_STRBUF_AUTO_DESTROY machine = ffStrbufCreate();
        ffSysctlGetString("hw.machine", &machine);
        if (ffStrbufStartsWithS(&machine, "iPad")) {
            ffStrbufSetStatic(&os->id, "ipados");
            ffStrbufSetStatic(&os->name, "iPadOS");
        } else {
            ffStrbufSetStatic(&os->id, "ios");
            ffStrbufSetStatic(&os->name, "iOS");
        }
    }
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
