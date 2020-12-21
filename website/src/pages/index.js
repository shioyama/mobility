import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
import Remarkable from 'remarkable';
import RemarkableReactRenderer from 'remarkable-react';
import hljs from 'highlight.js';
import ruby from 'highlight.js/lib/languages/ruby';
import 'highlight.js/styles/railscasts.css';
hljs.registerLanguage('ruby', ruby);
 
const md = new Remarkable();
md.renderer = new RemarkableReactRenderer({
  components: {
    pre: ({ content, params: language }) => (
      <pre className="code hljs" dangerouslySetInnerHTML={ { __html:
        hljs.highlight(language, content).value,
      } } />
    ),
  }
});

function Demo() {
  return md.render(`
## I18n for Model Data

Choose a backend to store your translations:

\`\`\`rb
Mobility.configure do
  plugins do
    backend :key_value
    active_record
    reader
    writer
    # ...
  end
end
\`\`\`

Define a model and \`translate\` it:

\`\`\`rb
class Post < ApplicationRecord
  extend Mobility
  translates :title, :subtitle
end
\`\`\`

Assign attributes:

\`\`\`rb
post = Post.new(
  title: "Introduction to Mobility",
  subtitle: "Translating Model Data is Easy"
)
post.title
#=> "Mobility"
post.subtitle
#=> "Translating Model Data is Easy"
post.save
\`\`\`

Translate them:

\`\`\`rb
Mobility.with_locale(:ja) do
  post.title = "Mobilityの紹介"
  post.subtitle = "モデルデータの翻訳は簡単"
end

post.title
#=> "Mobilityの紹介"

post.subtitle
#=> "モデルデータの翻訳を簡単に"
\`\`\`


And find them back:

\`\`\`rb
post = Post.i18n.find_by(title: "Introduction to Mobility")
#=> #<Post id: 1, ...>

post.title
#=> "Introduction to Mobility"
\`\`\`


Or this:

\`\`\`rb
Post.i18n do
  title.matches("%Mobility%")
end

# SELECT "posts".* FROM "posts"
# LEFT OUTER JOIN "mobility_string_translations" "Post_title_en_string_translations"
#   ON "Post_title_en_string_translations"."key" = 'title'
#   AND "Post_title_en_string_translations"."locale" = 'en'
#   AND "Post_title_en_string_translations"."translatable_type" = 'Post'
#   AND "Post_title_en_string_translations"."translatable_id" = "posts"."id"
# WHERE "Post_title_en_string_translations"."value" ILIKE '%Mobility%'
\`\`\`

And much, much more.

`);
};

function Feature({imageUrl, title, description}) {
  const imgUrl = useBaseUrl(imageUrl);
  return (
    <div className={clsx('col col--4', styles.feature)}>
      {imgUrl && (
        <div className="text--center">
          <img className={styles.featureImage} src={imgUrl} alt={title} />
        </div>
      )}
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

function Hero() {
  const context = useDocusaurusContext();
  const { siteConfig = {} } = context;
  return  (
    <header className='hero hero--light'>
      <div className="container margin-vert--lg">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <Link
          className={clsx(
            'button button--outline button--primary button--lg',
            styles.getStarted,
          )}
          to={useBaseUrl('docs/installation')}>
          Get Started
        </Link>
        <Link
          className={clsx(
            'button button--outline button--primary button--lg',
            styles.getStarted,
          )}
          to={useBaseUrl('docs/upgrading-to-version-1')}>
          Upgrading to 1.0
        </Link>
      </div>
    </header>
  );
}

function Home() {
  const context = useDocusaurusContext();
  const {siteConfig = {}} = context;
  return (
    <Layout
      title={`Mobility · Pluggable Ruby Translation Framework`}
      description="I18n for your Model Data">
      <Hero />
      <main>
        <section className="mainContainer">
          <div className="container">
            <Demo />
          </div>
        </section>
      </main>
    </Layout>
  );
}

export default Home;
