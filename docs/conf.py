from datetime import datetime


extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'

project = u'PDSA'
year = datetime.now().year
copyright = u'%d Andrii Gakhov' % year

exclude_patterns = ['_build']

html_theme = 'alabaster'
html_sidebars = {
    '**': [
        'about.html',
        'navigation.html',
        'relations.html',
        'searchbox.html',
        'donate.html',
    ]
}
html_theme_options = {
    'description': "Probabilistic Data Structures and Algorithms in Python",
    'github_user': 'gakhov',
    'github_repo': 'pdsa',
    'fixed_sidebar': True,
}

extensions.append('releases')
releases_github_path = 'gakhov/pdsa'
releases_unstable_prehistory = True
