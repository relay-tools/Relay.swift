module.exports = {
  title: "Relay.swift",
  tagline: "",
  url: "https://relay-tools.github.io",
  baseUrl: "/Relay.swift/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.ico",
  organizationName: "relay-tools",
  projectName: "Relay.swift",
  themeConfig: {
    prism: {
      additionalLanguages: ["swift"],
    },
    navbar: {
      title: "Relay.swift",
      items: [
        {
          type: "doc",
          docId: "index",
          label: "Docs",
          position: "left",
        },
        {
          to: "docs/knowledge-base",
          activeBasePath: "docs/knowledge-base",
          label: "Knowledge base",
          position: "left",
        },
        {
          to: "releases/",
          activeBasePath: "releases",
          label: "Releases",
          position: "left",
        },
        {
          href: "https://github.com/relay-tools/Relay.swift",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            {
              label: "Style Guide",
              to: "docs/",
            },
            {
              label: "Second Doc",
              to: "docs/doc2/",
            },
          ],
        },
        {
          title: "Community",
          items: [
            {
              label: "Stack Overflow",
              href: "https://stackoverflow.com/questions/tagged/docusaurus",
            },
            {
              label: "Discord",
              href: "https://discordapp.com/invite/docusaurus",
            },
            {
              label: "Twitter",
              href: "https://twitter.com/docusaurus",
            },
          ],
        },
        {
          title: "More",
          items: [
            {
              label: "GitHub",
              href: "https://github.com/relay-tools/Relay.swift",
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} My Project, Inc. Built with Docusaurus.`,
    },
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          sidebarPath: require.resolve("./sidebars.js"),
          // Please change this to your repo.
          editUrl:
            "https://github.com/relay-tools/Relay.swift/edit/main/website/",
        },
        blog: false,
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],
  plugins: [
    [
      "@docusaurus/plugin-content-blog",
      {
        id: "release-notes",
        routeBasePath: "releases",
        path: "./release-notes",
        blogTitle: "Release notes",
        blogSidebarCount: 10,
        blogSidebarTitle: "Recent releases",
        showReadingTime: false,
      },
    ],
  ],
};
