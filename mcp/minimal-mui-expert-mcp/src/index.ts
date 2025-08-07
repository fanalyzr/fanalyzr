#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';

const server = new Server(
  {
    name: 'minimal-mui-expert',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Minimal MUI Template knowledge base
const MINIMAL_MUI_KNOWLEDGE = {
  overview: {
    description: 'Professional React Kit built with Material-UI v6.5.0 components',
    versions: ['Next.js', 'Vite'],
    features: [
      'Ready-to-use Material-UI components',
      'Complete Figma design file',
      'Customizable theming system',
      'Light/dark mode support',
      'Right-to-left support',
      'Form validation',
      'Responsive design',
    ],
  },

  structure: {
    commonFolders: [
      'src/components/ - Reusable UI components',
      'src/sections/ - Page-specific sections',
      'src/layouts/ - Layout components (Dashboard, Auth, etc.)',
      'src/theme/ - Theme configuration and customization',
      'src/hooks/ - Custom React hooks',
      'src/utils/ - Utility functions',
      'src/pages/ - Page components',
      'src/assets/ - Static assets (images, icons, etc.)',
      'public/ - Public static files',
    ],
    keyFiles: [
      'src/theme/index.js - Main theme configuration',
      'src/App.js - Main application component',
      'src/routes/ - Routing configuration',
      'src/config-global.js - Global configuration',
    ],
  },

  components: {
    layout: [
      'DashboardLayout - Main dashboard layout with sidebar',
      'AuthLayout - Authentication pages layout',
      'SimpleLayout - Simple layout for basic pages',
      'CompactLayout - Compact layout for minimal pages',
    ],

    common: [
      'CustomBreadcrumbs - Breadcrumb navigation',
      'Iconify - Icon component wrapper',
      'Scrollbar - Custom scrollbar component',
      'SvgColor - SVG icon with color support',
      'Label - Status/category label component',
      'MenuPopover - Dropdown menu component',
      'NavSection - Navigation section component',
      'SearchNotFound - Empty search state',
      'ConfirmDialog - Confirmation dialog',
    ],

    forms: [
      'RHFTextField - React Hook Form text field',
      'RHFSelect - React Hook Form select',
      'RHFCheckbox - React Hook Form checkbox',
      'RHFRadioGroup - React Hook Form radio group',
      'RHFSwitch - React Hook Form switch',
      'RHFSlider - React Hook Form slider',
      'RHFAutocomplete - React Hook Form autocomplete',
      'RHFUpload - React Hook Form file upload',
    ],

    dataDisplay: [
      'DataGrid - Enhanced MUI DataGrid',
      'EmptyContent - Empty state component',
      'Chart - Chart.js integration',
      'Carousel - Image/content carousel',
      'Timeline - Timeline component',
      'Tree - Tree view component',
    ],
  },

  theming: {
    structure: [
      'palette.js - Color palette configuration',
      'typography.js - Typography settings',
      'shadows.js - Box shadow definitions',
      'customShadows.js - Custom shadow utilities',
      'globalStyles.js - Global CSS styles',
      'components/ - Component style overrides',
    ],

    customization: [
      'Primary/secondary color configuration',
      'Dark/light mode toggle',
      'Typography scale and fonts',
      'Spacing and breakpoints',
      'Component style overrides',
      'Custom CSS variables',
    ],
  },

  commonPatterns: {
    pageStructure: `
// Standard page structure
import { Helmet } from 'react-helmet-async';
import { Container, Typography } from '@mui/material';
import { useSettingsContext } from 'src/components/settings';
import CustomBreadcrumbs from 'src/components/custom-breadcrumbs';

export default function PageName() {
  const settings = useSettingsContext();
  
  return (
    <>
      <Helmet>
        <title>Page Title</title>
      </Helmet>
      
      <Container maxWidth={settings.themeStretch ? false : 'xl'}>
        <CustomBreadcrumbs
          heading="Page Heading"
          links={[
            { name: 'Dashboard', href: '/' },
            { name: 'Current Page' },
          ]}
          sx={{ mb: 3 }}
        />
        
        {/* Page content */}
      </Container>
    </>
  );
}`,

    formHandling: `
// Form with React Hook Form
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as Yup from 'yup';
import FormProvider, { RHFTextField } from 'src/components/hook-form';

const schema = Yup.object().shape({
  name: Yup.string().required('Name is required'),
  email: Yup.string().email('Email must be valid').required('Email is required'),
});

export default function MyForm() {
  const methods = useForm({
    resolver: yupResolver(schema),
    defaultValues: { name: '', email: '' },
  });

  const { handleSubmit } = methods;

  const onSubmit = async (data) => {
    console.log('Form data:', data);
  };

  return (
    <FormProvider methods={methods} onSubmit={handleSubmit(onSubmit)}>
      <RHFTextField name="name" label="Name" />
      <RHFTextField name="email" label="Email" type="email" />
    </FormProvider>
  );
}`,

    dataTable: `
// DataGrid with custom columns
import { DataGrid } from '@mui/x-data-grid';
import { useTable, getComparator, emptyRows } from 'src/components/table';

const columns = [
  { field: 'id', headerName: 'ID', width: 90 },
  { field: 'name', headerName: 'Name', width: 200 },
  { field: 'email', headerName: 'Email', width: 250 },
  {
    field: 'actions',
    headerName: 'Actions',
    width: 120,
    renderCell: (params) => (
      <IconButton onClick={() => handleEdit(params.row.id)}>
        <Iconify icon="eva:edit-fill" />
      </IconButton>
    ),
  },
];

export default function DataTable({ data }) {
  return (
    <DataGrid
      rows={data}
      columns={columns}
      pageSize={10}
      checkboxSelection
      disableSelectionOnClick
    />
  );
}`,
  },

  bestPractices: [
    'Use the provided theme configuration instead of inline styles',
    'Leverage custom components like CustomBreadcrumbs and Iconify',
    'Follow the established folder structure for consistency',
    'Use React Hook Form with Yup validation for forms',
    'Implement proper error boundaries and loading states',
    'Use the settings context for theme customization',
    "Follow MUI's sx prop pattern for styling",
    "Implement responsive design using MUI's breakpoint system",
    'Use proper TypeScript types when available',
  ],

  troubleshooting: {
    common_issues: [
      {
        issue: 'Theme not applying correctly',
        solution: 'Ensure ThemeProvider wraps your app and theme is properly imported',
      },
      {
        issue: 'Icons not displaying',
        solution: 'Check Iconify component usage and icon name format',
      },
      {
        issue: 'Form validation errors',
        solution: 'Verify Yup schema matches form field names and RHF setup',
      },
      {
        issue: 'Layout issues on mobile',
        solution: 'Check Container maxWidth settings and responsive breakpoints',
      },
    ],
  },
};

// Define available tools
const tools: Tool[] = [
  {
    name: 'get_template_overview',
    description: 'Get comprehensive overview of the Minimal MUI React Template',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'get_component_info',
    description: 'Get detailed information about specific components in the template',
    inputSchema: {
      type: 'object',
      properties: {
        component_type: {
          type: 'string',
          description: 'Type of component (layout, form, common, dataDisplay)',
          enum: ['layout', 'form', 'common', 'dataDisplay', 'all'],
        },
      },
      required: ['component_type'],
    },
  },
  {
    name: 'get_code_example',
    description: 'Get code examples for common patterns in the template',
    inputSchema: {
      type: 'object',
      properties: {
        pattern: {
          type: 'string',
          description: 'Pattern type to get example for',
          enum: ['pageStructure', 'formHandling', 'dataTable', 'theming'],
        },
      },
      required: ['pattern'],
    },
  },
  {
    name: 'get_folder_structure',
    description: 'Get recommended folder structure and file organization',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'get_theming_guide',
    description: 'Get comprehensive theming and customization guidance',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'troubleshoot_issue',
    description: 'Get help troubleshooting common issues with the template',
    inputSchema: {
      type: 'object',
      properties: {
        issue_description: {
          type: 'string',
          description: "Description of the issue you're experiencing",
        },
      },
      required: ['issue_description'],
    },
  },
  {
    name: 'get_best_practices',
    description: 'Get best practices for working with the Minimal MUI template',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'create_component_template',
    description: 'Generate a component template following Minimal MUI patterns',
    inputSchema: {
      type: 'object',
      properties: {
        component_name: {
          type: 'string',
          description: 'Name of the component to create',
        },
        component_type: {
          type: 'string',
          description: 'Type of component',
          enum: ['page', 'form', 'table', 'dialog', 'card', 'custom'],
        },
        features: {
          type: 'array',
          items: { type: 'string' },
          description: 'Features to include (breadcrumbs, form_validation, table_actions, etc.)',
        },
      },
      required: ['component_name', 'component_type'],
    },
  },
];

// Tool handlers
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'get_template_overview':
        return {
          content: [
            {
              type: 'text',
              text: `# Minimal MUI React Template Overview

${MINIMAL_MUI_KNOWLEDGE.overview.description}

## Key Features:
${MINIMAL_MUI_KNOWLEDGE.overview.features.map((f) => `• ${f}`).join('\n')}

## Available Versions:
${MINIMAL_MUI_KNOWLEDGE.overview.versions.join(', ')}

## Template Structure:
This template provides a complete React dashboard solution built on Material-UI v6.5.0 with both free and premium versions available. It includes comprehensive theming, form handling, data display components, and responsive layouts.

The template is designed for rapid development of admin dashboards, client portals, and web applications with a professional, modern design system.`,
            },
          ],
        };

      case 'get_component_info':
        const componentType = args?.component_type as string;
        let componentInfo = '';

        if (componentType === 'all') {
          componentInfo = Object.entries(MINIMAL_MUI_KNOWLEDGE.components)
            .map(
              ([category, components]) =>
                `## ${category.charAt(0).toUpperCase() + category.slice(1)} Components:\n${components.map((c) => `• ${c}`).join('\n')}`
            )
            .join('\n\n');
        } else if (
          MINIMAL_MUI_KNOWLEDGE.components[
            componentType as keyof typeof MINIMAL_MUI_KNOWLEDGE.components
          ]
        ) {
          const components =
            MINIMAL_MUI_KNOWLEDGE.components[
              componentType as keyof typeof MINIMAL_MUI_KNOWLEDGE.components
            ];
          componentInfo = `## ${componentType.charAt(0).toUpperCase() + componentType.slice(1)} Components:\n${components.map((c) => `• ${c}`).join('\n')}`;
        } else {
          componentInfo =
            'Unknown component type. Available types: layout, form, common, dataDisplay, all';
        }

        return {
          content: [{ type: 'text', text: componentInfo }],
        };

      case 'get_code_example':
        const pattern = args?.pattern as keyof typeof MINIMAL_MUI_KNOWLEDGE.commonPatterns;
        const example = MINIMAL_MUI_KNOWLEDGE.commonPatterns[pattern];

        return {
          content: [
            {
              type: 'text',
              text: example
                ? `# ${pattern} Example\n\n\`\`\`jsx\n${example}\n\`\`\``
                : 'Pattern not found',
            },
          ],
        };

      case 'get_folder_structure':
        return {
          content: [
            {
              type: 'text',
              text: `# Recommended Folder Structure

## Common Folders:
${MINIMAL_MUI_KNOWLEDGE.structure.commonFolders.map((f) => `• ${f}`).join('\n')}

## Key Files:
${MINIMAL_MUI_KNOWLEDGE.structure.keyFiles.map((f) => `• ${f}`).join('\n')}

This structure follows React best practices and ensures maintainable, scalable code organization.`,
            },
          ],
        };

      case 'get_theming_guide':
        return {
          content: [
            {
              type: 'text',
              text: `# Theming Guide

## Theme Structure Files:
${MINIMAL_MUI_KNOWLEDGE.theming.structure.map((f) => `• ${f}`).join('\n')}

## Customization Options:
${MINIMAL_MUI_KNOWLEDGE.theming.customization.map((c) => `• ${c}`).join('\n')}

## Quick Theme Customization Example:
\`\`\`javascript
// src/theme/palette.js
const palette = {
  primary: {
    main: '#1976d2', // Your brand primary color
    light: '#42a5f5',
    dark: '#1565c0',
  },
  secondary: {
    main: '#dc004e', // Your brand secondary color
  },
  // ... other color definitions
};
\`\`\`

The theme system is fully integrated with MUI's theming capabilities, allowing for comprehensive customization while maintaining design consistency.`,
            },
          ],
        };

      case 'troubleshoot_issue':
        const issueDescription = args?.issue_description as string;
        let solution = 'Please provide more specific details about your issue.';

        // Simple keyword matching for common issues
        const commonIssue = MINIMAL_MUI_KNOWLEDGE.troubleshooting.common_issues.find((item) =>
          issueDescription?.toLowerCase().includes(item.issue.toLowerCase().split(' ')[0])
        );

        if (commonIssue) {
          solution = `**Issue**: ${commonIssue.issue}\n**Solution**: ${commonIssue.solution}`;
        }

        return {
          content: [
            {
              type: 'text',
              text: `# Troubleshooting Help\n\n${solution}\n\n## Common Issues:\n${MINIMAL_MUI_KNOWLEDGE.troubleshooting.common_issues.map((item) => `• **${item.issue}**: ${item.solution}`).join('\n')}`,
            },
          ],
        };

      case 'get_best_practices':
        return {
          content: [
            {
              type: 'text',
              text: `# Best Practices for Minimal MUI Template\n\n${MINIMAL_MUI_KNOWLEDGE.bestPractices.map((practice) => `• ${practice}`).join('\n')}`,
            },
          ],
        };

      case 'create_component_template':
        const componentName = args?.component_name as string;
        const compType = args?.component_type as string;
        const features = (args?.features as string[]) || [];

        let template = generateComponentTemplate(componentName, compType, features);

        return {
          content: [
            {
              type: 'text',
              text: `# Generated Component Template: ${componentName}\n\n\`\`\`jsx\n${template}\n\`\`\``,
            },
          ],
        };

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error instanceof Error ? error.message : String(error)}`,
        },
      ],
      isError: true,
    };
  }
});

// Helper function to generate component templates
function generateComponentTemplate(name: string, type: string, features: string[]): string {
  const includesBreadcrumbs = features.includes('breadcrumbs');
  const includesForm = features.includes('form_validation');
  const includesTable = features.includes('table_actions');

  let imports = [
    "import { Helmet } from 'react-helmet-async';",
    "import { Container, Typography, Card, CardContent } from '@mui/material';",
    "import { useSettingsContext } from 'src/components/settings';",
  ];

  if (includesBreadcrumbs) {
    imports.push("import CustomBreadcrumbs from 'src/components/custom-breadcrumbs';");
  }

  if (includesForm) {
    imports.push("import { useForm } from 'react-hook-form';");
    imports.push("import { yupResolver } from '@hookform/resolvers/yup';");
    imports.push("import * as Yup from 'yup';");
    imports.push("import FormProvider, { RHFTextField } from 'src/components/hook-form';");
  }

  if (includesTable) {
    imports.push("import { DataGrid } from '@mui/x-data-grid';");
    imports.push("import { IconButton } from '@mui/material';");
    imports.push("import Iconify from 'src/components/iconify';");
  }

  let componentBody = '';

  switch (type) {
    case 'page':
      componentBody = `
  const settings = useSettingsContext();
  
  return (
    <>
      <Helmet>
        <title>${name}</title>
      </Helmet>
      
      <Container maxWidth={settings.themeStretch ? false : 'xl'}>
        ${
          includesBreadcrumbs
            ? `
        <CustomBreadcrumbs
          heading="${name}"
          links={[
            { name: 'Dashboard', href: '/' },
            { name: '${name}' },
          ]}
          sx={{ mb: 3 }}
        />`
            : ''
        }
        
        <Card>
          <CardContent>
            <Typography variant="h4" gutterBottom>
              ${name} Content
            </Typography>
            {/* Add your page content here */}
          </CardContent>
        </Card>
      </Container>
    </>
  );`;
      break;

    case 'form':
      componentBody = includesForm
        ? `
  const schema = Yup.object().shape({
    name: Yup.string().required('Name is required'),
  });

  const methods = useForm({
    resolver: yupResolver(schema),
    defaultValues: { name: '' },
  });

  const { handleSubmit } = methods;

  const onSubmit = async (data) => {
    console.log('Form data:', data);
  };

  return (
    <Card sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        ${name}
      </Typography>
      
      <FormProvider methods={methods} onSubmit={handleSubmit(onSubmit)}>
        <RHFTextField name="name" label="Name" sx={{ mb: 2 }} />
        {/* Add more form fields here */}
      </FormProvider>
    </Card>
  );`
        : `
  return (
    <Card sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        ${name}
      </Typography>
      {/* Add your form content here */}
    </Card>
  );`;
      break;

    default:
      componentBody = `
  return (
    <Card sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        ${name}
      </Typography>
      {/* Add your component content here */}
    </Card>
  );`;
  }

  return `${imports.join('\n')}

export default function ${name}() {${componentBody}
}`;
}

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Minimal MUI Expert MCP Server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error in main():', error);
  process.exit(1);
});
