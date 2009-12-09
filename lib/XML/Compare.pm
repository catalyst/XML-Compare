## ----------------------------------------------------------------------------
# Copyright (C) 2009 NZ Registry Services
## ----------------------------------------------------------------------------
package XML::Compare;

use 5.006;
use strict;
use warnings;
use XML::LibXML;

our $VERSION = '0.01';
our $VERBOSE = 0;

my $PARSER = XML::LibXML->new();

my $has = {
    localname => {
        # not Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    namespaceURI => {
        # not Comment, Text, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    attributes => {
        # not Attr, Comment, CDATASection
        'XML::LibXML::Element' => 1,
    },
    value => {
        # not Element, Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Comment' => 1,
    },
    data => {
        # not Element, Attr
        'XML::LibXML::CDATASection' => 1,
        'XML::LibXML::Comment' => 1,
        'XML::LibXML::Text' => 1,
    },
};

# acts almost like an assertion (either returns true or throws an exception)
sub same {
    my ($xml1, $xml2) = @_;
    # either throws an exception, or returns true
    return _compare($xml1, $xml2);
}

sub is_same {
    my ($xml1, $xml2) = @_;
    # catch the exception and return true or false
    eval { _compare($xml1, $xml2); };
    if ( $@ ) {
        return 0;
    }
    return 1;
}

sub is_different {
    my ($xml1, $xml2) = @_;
    return !is_same($xml1, $xml2);
}

sub _compare {
    my ($xml1, $xml2) = @_;
    if ( $VERBOSE ) {
        print '-' x 79, "\n";
        print $xml1;
        print '-' x 79, "\n";
        print $xml2;
        print '-' x 79, "\n";
    }

    my $parser = XML::LibXML->new();
    my $doc1 = $parser->parse_string( $xml1 );
    my $doc2 = $parser->parse_string( $xml2 );
    return _are_docs_same($doc1, $doc2);
}

sub _are_docs_same {
    my ($doc1, $doc2) = @_;
    return _are_nodes_same( 1, $doc1->documentElement(), $doc2->documentElement() );
}

sub _are_nodes_same {
    my ($l, $node1, $node2) = @_;
    _msg($l, "\\ got (" . ref($node1) . ", " . ref($node2) . ")");

    # firstly, check that the node types are the same
    my $nt1 = $node1->nodeType();
    my $nt2 = $node2->nodeType();
    if ( $nt1 eq $nt2 ) {
        _same($l, "nodeType=$nt1");
    }
    else {
        _outit($l, 'node types are different', $nt1, $nt2);
        die sprintf 'node types are different (%s, %s)', $nt1, $nt2;
    }

    # if these nodes are Text, compare the contents
    if ( $has->{data}{ref $node1} ) {
        my $data1 = $node1->data();
        my $data2 = $node2->data();
        # _msg($l, ": data ($data1, $data2)");
        if ( $data1 eq $data2 ) {
            _same($l, "data");
        }
        else {
            _outit($l, 'data differs', $data1, $data2);
            die sprintf 'data differs: (%s, %s)', $data1, $data2;
        }
    }

    # if these nodes are Attr, compare the contents
    if ( $has->{value}{ref $node1} ) {
        my $val1 = $node1->getValue();
        my $val2 = $node2->getValue();
        # _msg($l, ": val ($val1, $val2)");
        if ( $val1 eq $val2 ) {
            _same($l, "value");
        }
        else {
            _outit($l, 'attr node values differs', $val1, $val2);
            die sprintf "attr node values differs (%s, %s)", $val1, $val2
        }
    }

    # check that the nodes are the same name (localname())
    if ( $has->{localname}{ref $node1} ) {
        my $ln1 = $node1->localname();
        my $ln2 = $node2->localname();
        if ( $ln1 eq $ln2 ) {
            _same($l, 'localname');
        }
        else {
            _outit($l, 'node names are different', $ln1, $ln2);
            die sprintf 'node names are different: ', $ln1, $ln2;
        }
    }

    # check that the nodes are the same namespace
    if ( $has->{namespaceURI}{ref $node1} ) {
        my $ns1 = $node1->namespaceURI();
        my $ns2 = $node2->namespaceURI();
        # _msg($l, ": namespaceURI ($ns1, $ns2)");
        if ( defined $ns1 and defined $ns2 ) {
            if ( $ns1 eq $ns2 ) {
                _same($l, 'namespaceURI');
            }
            else {
                _outit($l, 'namespaceURIs are different', $node1->namespaceURI(), $node2->namespaceURI());
                die sprintf 'namespaceURIs are different: (%s, %s)', $ns1, $ns2;
            }
        }
        elsif ( !defined $ns1 and !defined $ns2 ) {
            _same($l, 'namespaceURI (not defined for either node)');
        }
        else {
            _outit($l, 'namespaceURIs are defined/not defined', $ns1, $ns2);
            die sprintf 'namespaceURIs are defined/not defined: (%s, %s)', ($ns1 || '[undef]'), ($ns2 || '[undef]');
        }
    }

    # check the attribute list is the same length
    if ( $has->{attributes}{ref $node1} ) {
        # get just the Attrs and sort them by namespaceURI:localname
        my @attr1 = sort { _fullname($a) cmp _fullname($b) } grep { defined and $_->isa('XML::LibXML::Attr') } $node1->attributes();
        my @attr2 = sort { _fullname($a) cmp _fullname($b) } grep { defined and $_->isa('XML::LibXML::Attr') } $node2->attributes();
        if ( scalar @attr1 == scalar @attr2 ) {
            _same($l, 'attribute length (' . (scalar @attr1) . ')');
        }
        else {
            _outit($l, 'attribute list lengths differ', scalar @attr1, scalar @attr2);
            die sprintf 'attribute list lengths differ: (%d, %d)', scalar @attr1, scalar @attr2;
        }

        # for each attribute, check they are all the same
        my $total_attrs = scalar @attr1;
        for (my $i = 0; $i < scalar @attr1; $i++ ) {
            # recurse down (either an exception will be thrown, or all are correct
            _are_nodes_same( $l+1, $attr1[$i], $attr2[$i] );
        }
    }

    # don't need to compare or care about Comments
    my @nodes1 = grep { ! $_->isa('XML::LibXML::Comment') and !($_->isa("XML::LibXML::Text") && ($_->data =~ /\A\s*\Z/)) } $node1->childNodes();
    my @nodes2 = grep { ! $_->isa('XML::LibXML::Comment') and !($_->isa("XML::LibXML::Text") && ($_->data =~ /\A\s*\Z/))  } $node2->childNodes();

    # check that the nodes contain the same number of children
    if ( @nodes1 != @nodes2 ) {
        _outit($l, 'different number of child nodes', scalar @nodes1, scalar @nodes2);
        die sprintf 'different number of child nodes: (%d, %d)', scalar @nodes1, scalar @nodes2;
    }

    # foreach of it's children, compare them
    my $total_nodes = scalar @nodes1;
    for (my $i = 0; $i < $total_nodes; $i++ ) {
        # recurse down (either an exception will be thrown, or all are correct
        _are_nodes_same( $l+1, $nodes1[$i], $nodes2[$i] );
    }

    _msg($l, '/');
    return 1;
}

sub _fullname {
    my ($node) = @_;
    my $name = '';
    $name .= $node->namespaceURI() . ':' if $node->namespaceURI();
    $name .= $node->localname();
    # print "name=$name\n";
    return $name;
}

sub _same {
    my ($l, $msg) = @_;
    return unless $VERBOSE;
    print '' . ('  ' x $l) . "= $msg\n";
}

sub _msg {
    my ($l, $msg) = @_;
    return unless $VERBOSE;
    print ' ' . ('  ' x ($l-1)) . "$msg\n";
}

sub _outit {
    my ($l, $msg, $v1, $v2) = @_;
    return unless $VERBOSE;
    print '' . ('  ' x $l) . "! $msg:\n";
    print '' . ('  ' x $l) . '. ' . ($v1 || '[undef]') . "\n";
    print '' . ('  ' x $l) . '. ' . ($v2 || '[undef]') . "\n";
}

1;
__END__

=head1 NAME

XML::Compare - Test if two XML documents semantically the same

=head1 SYNOPSIS

    use XML::Compare tests => 2;

    my $xml1 = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";
    my $xml2 = "<f:foo xmlns:f="urn:message"><f:bar baz="buzz">text</f:bar></f:foo>";

    eval { XML::Compare::same($xml1, $xml2); };
    if ( $@ ) {
        print "same\n";
    }
    else {
        print "different: $@\n";
    }

=head1 DESCRIPTION

This module allows you to test if two XML documents are semantically the
same. This also holds true if different prefixes are being used for the xmlns,
or if there is a default xmlns in place.

This modules ignores XML Comments.

=head1 SUBROUTINES

=over 4

=item same($xml1, $xml2)

Returns true if the two xml strings are semantically the same.

If they are not the same, it throws an exception with a description in $@ as to
why they aren't.

=item is_same($xml1, $xml2)

Returns true if the two xml strings are semantically the same.

Returns false otherwise. No diagnostic information is available.

=item is_different($xml1, $xml2)

Returns true if the two xml strings are semantically different. No diagnostic
information is available.

Returns false otherwise.

=back

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<XML::LibXML>

=head1 AUTHOR

Andrew Chilton, E<lt>andychilton@gmail.com<gt>, E<lt>andy@catalyst dot net dot nz<gt>

http://www.chilts.org/blog/

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by New Zealand Registry
Services, http://www.nzrs.net.nz/

The work is being carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2009, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut
