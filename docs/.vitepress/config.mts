import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Hydrogen",
  description: "Battery Powered Game Development",

  head: [
    ['link', { rel: 'icon', href: 'bubbles_gradient.png' }]
  ],

  themeConfig: {
    logo: 'bubbles_gradient.png',

    search: {
      provider: "local"
    },

    footer: {
      message: 'Released under the <a href="https://github.com/teamhydrogen/hydrogen/blob/master/LICENSE">MIT License</a>.',
      copyright: `Copyright © 2025 <a href="https://github.com/teamhydrogen">Team Hydrogen</a> and it's contributors.`
    },

    nav: [
      { text: 'Home', link: '/' },
    ],

    sidebar: [
      {
        text: '👋 Introduction',
        items: [
          { text: 'What is Hydrogen?', link: '/info' },
          { text: 'Installation', link: '/installation' },
        ]
      },
      {
        text: "🫧 Using Hydrogen",
        items: [
          { text: 'Bootstrapping', link: '/bootstrapping' },
        ]

      },
      {
        text: "❓ Help us out!",
        items: [
          { text: 'Contributing', link: '/contributing/contributing' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/teamhydrogen/hydrogen' },
      { icon: 'discord', link: 'https://discord.gg/mchCdAFPWU' },
    ]
  },

  cleanUrls: true
})
