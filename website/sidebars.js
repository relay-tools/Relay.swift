module.exports = {
  docs: [
    "index",
    {
      type: "category",
      label: "Getting started",
      items: [
        "getting-started/installation",
        "getting-started/relay-environment",
        "getting-started/fetching-data",
        "getting-started/fragments",
        "getting-started/mutations",
      ],
    },
    {
      type: "category",
      label: "API reference",
      collapsed: false,
      items: [
        {
          type: "category",
          label: "Relay.swift",
          items: [
            "api/intro-relay",
            "api/graphql",
            "api/environment",
            "api/network",
            "api/store",
            "api/record-source-selector-proxy",
            "api/record-proxy",
            "api/connection-handler",
            "api/mock-environment",
          ],
        },
        {
          type: "category",
          label: "Relay in SwiftUI",
          items: [
            "api/intro-relay-swift-ui",
            "api/relay-environment-modifier",
            "api/relay-environment-wrapper",
            "api/query",
            "api/fragment",
            "api/refetchable-fragment",
            "api/pagination-fragment",
            "api/mutation",
            "api/preview-payload",
          ],
        },
      ],
    },
    {
      type: "category",
      label: "Development",
      items: ["development/contributing"],
    },
  ],
};
