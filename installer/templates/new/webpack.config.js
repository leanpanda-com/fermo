const ManifestPlugin = require('webpack-manifest-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const webpack = require('webpack')

const mode = (process.env.NODE_ENV === 'development') ? 'development' : 'production'

let assetNaming = null
let cssFilenameTemplate = null
let jsFilenameTemplate = null
if (mode === 'production') {
  assetNaming = '[path][name]-[hash:6].[ext]'
  cssFilenameTemplate = 'stylesheets/[name]-[hash:6].css'
  jsFilenameTemplate = 'javascripts/[name]-[hash:6].js'
} else {
  assetNaming = '[path][name].[ext]'
  cssFilenameTemplate = 'stylesheets/[name].css'
  jsFilenameTemplate = 'javascripts/[name].js'
}

module.exports = {
  context: __dirname + '/priv/source',
  entry: {
    application: './javascripts/application.js',
    style: './stylesheets/application.sass'
  },
  resolve: {
    modules: [
      'javascripts',
      __dirname + '/node_modules'
    ]
  },
  output: {
    path: __dirname + '/build',
    publicPath: '/', // prepend '/' to image paths resolved from 'url()' in SASS
    filename: jsFilenameTemplate
  },
  mode,
  optimization: {
    splitChunks: {
      cacheGroups: {
        styles: {
          name: 'styles',
          test: /\.css$/,
          chunks: 'all',
          enforce: true,
        },
      },
    },
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: [
          {loader: 'import-glob-loader'}
        ]
      },
      {
        test: /\.(gif|ico|jpg|png|svg|eot|ttf|woff|woff2)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: assetNaming,
              esModule: false,
              sourceMap: false
            }
          }
        ]
      },
      {
        test: /.*\.sass$/,
        use: [
          MiniCssExtractPlugin.loader,
          {loader: 'css-loader'},
          {loader: 'postcss-loader'},
          {
            loader: 'sass-loader',
            options: {
              sassOptions: {
                includePaths: ['node_modules/normalize-scss/sass']
              }
            }
          },
          {loader: 'import-glob-loader'}
        ]
      },
      {
        test: /favicons\/(site\.webmanifest|browserconfig\.xml)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: '[path][name]-[hash:6].[ext]'
            }
          },
          {
            loader: 'app-manifest-loader'
          }
        ]
      }
    ]
  },
  devServer: {
    headers: {
      "Access-Control-Allow-Origin": "*"
    }
  },
  plugins: [
    new ManifestPlugin(),
    new MiniCssExtractPlugin({
      filename: cssFilenameTemplate
    })
  ]
}
