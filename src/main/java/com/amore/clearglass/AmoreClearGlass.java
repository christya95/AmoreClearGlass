package com.amore.clearglass;

import com.hypixel.hytale.logger.HytaleLogger;
import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;
import javax.annotation.Nonnull;

/**
 * Asset-pack plugin: registers the jar’s Server/Common assets (clear + stained glass panes).
 * Rendering is driven entirely by item JSON and textures; this class only loads the pack.
 */
public class AmoreClearGlass extends JavaPlugin {

    private static final HytaleLogger LOG = HytaleLogger.get("AmoreClearGlass");

    public AmoreClearGlass(@Nonnull JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        LOG.atInfo().log("AmoreClearGlass loaded (asset pack).");
    }
}
