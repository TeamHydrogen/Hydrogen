import { defineConfig } from "vitepress";
import { tabsMarkdownPlugin } from "vitepress-plugin-tabs";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Hydrogen",
  description: "Battery Powered Game Development",

  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin);
    },
  },

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [{ text: "Home", link: "/" }],

    sidebar: [
      {
        text: "Introduction",
        items: [
          { text: "Why", link: "/resources/1-why" },
          { text: "Installation", link: "/resources/2-installation" },
        ],
      },
      {
        text: "Crash Course",
        items: [
          { text: "Loader Setup", link: "/resources/3-setup" },
          { text: "Lifecycles", link: "/resources/4-lifecycles" },
          { text: "Player Handler", link: "/resources/5-playerhandler" },
          { text: "Logging", link: "/resources/6-logging" },
          { text: "Sound Handler", link: "/resources/7-sound" },
          { text: "FunctionLib", link: "/resources/8-functionlib" },
        ],
      },
    ],

    logo: "logo_coloured.svg",

    socialLinks: [
      { icon: "github", link: "https://github.com/teamhydrogen/hydrogen" },
      { icon: "discord", link: "https://discord.gg/mchCdAFPWU" },
    ],
  },
  head: [["link", { rel: "icon", href: "logo_coloured.svg" }]],
  cleanUrls: true,
});
