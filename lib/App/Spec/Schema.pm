use strict;
use warnings;
package App::Spec::Schema;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';
our @EXPORT_OK = qw/ $SCHEMA /;

our $SCHEMA;

# START INLINE
$SCHEMA = {
  'additionalProperties' => '',
  'definitions' => {
    'bool' => {
      'anyOf' => [
        {
          'type' => 'boolean'
        },
        {
          'type' => 'integer'
        },
        {
          'maxLength' => 0,
          'type' => 'string'
        }
      ]
    },
    'command' => {
      'additionalProperties' => '',
      'properties' => {
        'description' => {
          'type' => 'string'
        },
        'op' => {
          'type' => 'string'
        },
        'options' => {
          '$ref' => '#/definitions/options'
        },
        'parameters' => {
          '$ref' => '#/definitions/options'
        },
        'subcommands' => {
          'additionalProperties' => '',
          'patternProperties' => {
            '^[a-zA-Z0-9_]+$' => {
              '$ref' => '#/definitions/command'
            }
          },
          'type' => 'object'
        },
        'summary' => {
          'type' => 'string'
        }
      },
      'type' => 'object'
    },
    'option' => {
      'additionalProperties' => '',
      'anyOf' => [
        {
          'required' => [
            'name'
          ]
        },
        {
          'required' => [
            'spec'
          ]
        }
      ],
      'properties' => {
        'aliases' => {
          'items' => {
            'type' => 'string'
          },
          'type' => 'array'
        },
        'completion' => {
          'oneOf' => [
            {
              'type' => 'object'
            },
            {
              '$ref' => '#/definitions/bool'
            }
          ]
        },
        'default' => {
          'type' => 'string'
        },
        'description' => {
          'type' => 'string'
        },
        'enum' => {
          'items' => {
            'type' => 'string'
          },
          'type' => 'array'
        },
        'mapping' => {
          '$ref' => '#/definitions/bool'
        },
        'multiple' => {
          '$ref' => '#/definitions/bool'
        },
        'name' => {
          'type' => 'string'
        },
        'required' => {
          '$ref' => '#/definitions/bool'
        },
        'spec' => {
          'type' => 'string'
        },
        'summary' => {
          'type' => 'string'
        },
        'type' => {
          'oneOf' => [
            {
              '$ref' => '#/definitions/optionTypeSimple'
            }
          ]
        },
        'unique' => {
          '$ref' => '#/definitions/bool'
        },
        'values' => {
          'additionalProperties' => '',
          'properties' => {
            'enum' => {
              'items' => {
                'type' => 'string'
              },
              'type' => 'array'
            },
            'mapping' => {
              'type' => 'object'
            },
            'op' => {
              'type' => 'string'
            }
          },
          'type' => 'object'
        }
      },
      'type' => [
        'object',
        'string'
      ]
    },
    'optionTypeSimple' => {
      'enum' => [
        'flag',
        'string',
        'integer',
        'file'
      ]
    },
    'options' => {
      'items' => {
        '$ref' => '#/definitions/option'
      },
      'type' => 'array'
    }
  },
  'properties' => {
    'abstract' => {
      'type' => 'string'
    },
    'appspec' => {
      'additionalProperties' => '',
      'properties' => {
        'version' => {
          'type' => 'number'
        }
      },
      'required' => [
        'version'
      ],
      'type' => 'object'
    },
    'class' => {
      'type' => 'string'
    },
    'description' => {
      'type' => 'string'
    },
    'markup' => {
      'type' => 'string'
    },
    'name' => {
      'type' => 'string'
    },
    'options' => {
      '$ref' => '#/definitions/options'
    },
    'parameters' => {
      '$ref' => '#/definitions/options'
    },
    'plugins' => {
      'items' => {
        'type' => 'string'
      },
      'type' => 'array'
    },
    'subcommands' => {
      'additionalProperties' => '',
      'patternProperties' => {
        '^[a-zA-Z0-9_]+$' => {
          '$ref' => '#/definitions/command'
        }
      },
      'type' => 'object'
    },
    'title' => {
      'type' => 'string'
    }
  },
  'required' => [
    'name',
    'appspec'
  ],
  'type' => 'object'
};
# END INLINE

1;
