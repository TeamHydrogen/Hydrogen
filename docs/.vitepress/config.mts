import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Hydrogen",
  description: "Battery Powered Game Development",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Installation', link: '/installation' },
          { text: 'Bootstrapping', link: '/bootstrapping' },
        ]
      }
    ],

    logo: '/assets/bubbles_gradient.png',

    socialLinks: [
      { icon: 'github', link: 'https://github.com/teamhydrogen/hydrogen' },
      { icon: 'discord', link: 'https://discord.gg/mchCdAFPWU' },
    ]
  },
  head: [
    ['link', { rel: 'icon', href: '../assets/bubbles_gradient.png' }]
  ],
  cleanUrls: true
})
