package com.amore.clearglass;

import com.hypixel.hytale.logger.HytaleLogger;
import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;
import javax.annotation.Nonnull;

/**
 * Asset-pack plugin: clear / stained glass blocks under {@code Amore_*} item IDs.
 * Textures are derived from the Minecraft "Clear Glass Pack" (DnatorGames) layout.
 */
public class AmoreClearGlass extends JavaPlugin {

    private static final HytaleLogger LOG = HytaleLogger.get("AmoreClearGlass");

    public AmoreClearGlass(@Nonnull JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        ((HytaleLogger.Api) LOG.atInfo()).log("AmoreClearGlass loaded (asset pack).");
    }
}
