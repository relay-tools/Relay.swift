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
      theme: require("prism-react-renderer/themes/github"),
      darkTheme: require("prism-react-renderer/themes/dracula"),
    },
    navbar: {
      title: "Relay.swift",
      items: [
        {
          type: "docsVersionDropdown",
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
      copyright: `Copyright © ${new Date().getFullYear()} Matt Moriarity.`,
    },
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          sidebarPath: require.resolve("./sidebars.js"),
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
